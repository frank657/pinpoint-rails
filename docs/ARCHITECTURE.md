# Pinpoint — Architecture

> Read the ADRs in `docs/decisions/` first — they are the locked decisions this document
> elaborates. Where this doc and an ADR disagree, the ADR wins (and this doc is the bug).

## 1. What Pinpoint is

A video note-taking & learning platform. Upload videos (Aliyun VOD) or paste a YouTube
link; take **timestamped notes** (point or range) and **rich-text notes**; label videos
inline with **Segments** and notes with **Categories**, **Tags**, and the BJJ
**Position/Technique** taxonomy; **share** and **fork** videos and notes; and track
**progress** as you watch.

The content model is **flat**: `Video → {Note, Video::Segment}`. There is **no** grouping
layer — the old Course/Curriculum/Folder and Notebook/Chapter/Item concepts were removed; do
not reintroduce them.

Primary use case: BJJ instructional study. Designed general-purpose for any video learning.

## 2. Tech stack & topology

- **Rails 8.1.3 monolith**, Ruby 3.3.2 (ADR 0001).
- **Inertia.js + React + Vite** frontend; **Tailwind** styling.
- **Devise** session auth; **Action Policy** authorization (policies in `app/policies/`).
- **PostgreSQL** multi-database (primary / queue / cache / cable).
- **Solid Queue/Cache/Cable**, **Sidekiq + Sidekiq Cron** for jobs.
- **acts_as_tenant** scoped to **Workspace** (ADR 0002).
- **Aliyun VOD** (video) + **Aliyun OSS** via Active Storage (ADR 0007), direct upload.
- FriendlyId, pg_search, Kaminari, Noticed, PaperTrail, Mobility.
- **Kamal + Thruster + Docker** deploy.

### Subdomains (ADR 0006)

```
pinpoint.com          → marketing / landing (public)
app.pinpoint.com      → authenticated user app   (Inertia + React)
admin.pinpoint.com    → admin panel (admin-only)  (Inertia + React)
```

Workspaces are **in-app state**, not subdomains.

## 3. The three-axis model (ADR 0004)

Everything below is sorted into exactly one axis. **Content** is shared/forkable;
**Taxonomy** labels content; **Per-user state** is private to (user, workspace).

```
            ┌─────────────────────────── Identity / tenancy ───────────────────────────┐
            │  User ──< Workspace::Membership >── Workspace      (global, NOT tenant)   │
            └──────────────────────────────────────────────────────────────────────────┘
                                   │ every model below is acts_as_tenant :workspace
   ┌───────────────────── AXIS 1: CONTENT (shared & forkable) ───────────────────────┐
   │  Video ──has_one── Vod (Aliyun)        Video ──< Video::Segment                  │
   │    │  (source: upload | youtube)                                                 │
   │    └──< Note   (timestamp point/range | rich_text; Action Text body; AS images)  │
   │  Share (polymorphic: Video | Note)     Fork (attribution back-reference)         │
   └─────────────────────────────────────────────────────────────────────────────────┘
   ┌───────────────────── AXIS 2: TAXONOMY (labels, curated) ────────────────────────┐
   │  Category ──< Note      Tag ──<>── Note (join)                                   │
   │  Position ──< Technique(from_position,to_position,kind) ──<>── Note              │
   └─────────────────────────────────────────────────────────────────────────────────┘
   ┌───────────────────── AXIS 3: PER-USER STATE (private) ──────────────────────────┐
   │  Progress(user, workspace, polymorphic trackable)                               │
   └─────────────────────────────────────────────────────────────────────────────────┘
```

## 4. Canonical models

> Naming here is binding; deviations need an ADR. Nest a model under its parent when it only
> exists in relation to one (`Video::Segment`, `Workspace::Membership`) — see
> `docs/guides/models-guide.md`.

### Identity & tenancy (global — NOT acts_as_tenant)

- **User** — Devise login identity. `email`, `password`, `admin:boolean`. `has_many
  :memberships`, `has_many :workspaces, through:`. Has a `current_workspace` pointer
  (session-driven).
- **Workspace** — the tenant / "account for a topic" (ADR 0002). `name`, `slug`
  (FriendlyId). Members through `Workspace::Membership`.
- **Workspace::Membership** — join (`user_id`, `workspace_id`, `role`). Role enables future
  multi-member workspaces (`owner`/`member`).

### Axis 1 — Content (acts_as_tenant :workspace)

- **Video** — a watchable item. `source:enum { upload, youtube }`, `title`,
  `duration_seconds:float`, `youtube_id` (nullable). For uploads, `has_one :vod`. Forkable
  (ADR 0005); `Shareable`. `has_many :notes`, `has_many :segments` (`Video::Segment`).
- **Vod** — the Aliyun-backed media asset (ported, ADR 0007). `key` (Aliyun VideoId),
  `status:enum { uploading, uploaded, ready }`, `provider:enum { aliyun }`, `filename`,
  `duration`, `upload_expires_at`, `metadata:jsonb`. Has the `Vod::Providers` concern.
  **Reference-counted** by Videos (ADR 0005): destroy the Aliyun object only when the last
  Video referencing it is gone.
- **Video::Segment** — a labeled time-range inside one Video. `video_id`, `start_seconds`,
  `end_seconds` (nullable → point), `title`, `position` (order).
- **Note** — the heart of the app. UUID. `video_id` (nullable for standalone notes),
  `category_id` (nullable), `note_type:enum { timestamp, rich_text }`, `start_seconds`
  (nullable), `end_seconds` (nullable → range), Action Text rich `body` (images via Active
  Storage direct upload), `title`. `created_by`; `Shareable`; `has_paper_trail`. Full-text
  searchable (pg_search).
- **Share** — view-grant (ADR 0005). polymorphic `shareable` (Note/Video), `token`,
  visibility, optional grantee.
- **Fork** — attribution back-reference (ADR 0005). `source_type/source_id`,
  `source_workspace_id`, `target_type/target_id`, `target_workspace_id`. No data coupling.

### Axis 2 — Taxonomy (acts_as_tenant :workspace)

- **Category** — user-defined, for notes. `name`, unique per workspace. `has_many :notes`.
- **Tag** — free-form. `name`, unique per workspace. `has_and_belongs_to_many :notes` (join
  `note_tags`).
- **Position** — BJJ taxonomy node. `name`, `category:enum` (standing/guard/pin/back/leg/
  turtle), `dominance:enum` (dominant/neutral/inferior), self-referential `parent`.
- **Technique** — typed edge between positions. `name`, `from_position_id`,
  `to_position_id` (both nullable), `kind:enum { escape, sweep, pass, submission, transition,
  takedown }`. `has_and_belongs_to_many :notes`.

### Axis 3 — Per-user state (keyed by user + workspace; NEVER shared/forked)

- **Progress** — `user_id`, `workspace_id`, polymorphic `trackable` (Video today; the
  polymorphism leaves room for other trackables later), `completed_at` (nullable),
  `resume_seconds` (for video resume), `last_viewed_at`. Unique per
  `(user, workspace, trackable)`.

## 5. Video ingestion (ported VOD pipeline + YouTube)

**Upload (Aliyun VOD):** unchanged from method-channel's proven flow —
1. Client provisions a `Vod` → Aliyun `CreateUploadVideo` →
2. server returns Base64 `upload_address` + `upload_auth` (STS creds) + a signed id →
3. browser uploads **directly to Aliyun OSS** →
4. Aliyun webhooks: `FileUploadComplete` → `status: uploaded`; `TranscodeComplete` →
   `status: ready` + `duration` + cover image. Playback via `GetPlayInfo` (m3u8).

The show page also reconciles Vod status on load, so a video stuck at "uploading" (webhook
unreachable in dev) self-heals on first visit.

**YouTube:** paste a link → extract `youtube_id` → fetch title/duration → create a
`Video(source: youtube)`. No Vod, no upload. Player embeds YouTube; notes/segments work
identically against `*_seconds`.

The webhook controller runs **without a session** — it resolves the workspace from the
`Vod`/`Video` record and wraps tenant-scoped work in `ActsAsTenant.with_tenant` (ADR 0002).

## 6. Frontend (Inertia + React)

- Controllers render `render inertia: "Page", props: {...}`; pages live under
  `app/frontend/pages` (Vite). Shared layout per subdomain (`AppShell`).
- The signature screen is the **video page** (`videos/Show`): player on one side, a
  time-synced notes panel on the other; clicking a note seeks the player; creating a note
  captures the current `currentTime` as `start_seconds` (drag to set a range). Segment chips
  jump the player.
- Search (`Search` page + `SearchSpotlight` ⌘K modal) is full-text over **notes**.
- Rich-text notes use a React rich editor backed by Action Text; images go through Active
  Storage **direct upload** to Aliyun OSS.
- Theme: warm-cream "Tatami" palette via a Tailwind `@theme` remap (see iteration 0001).

## 7. Background jobs & realtime

- Aliyun webhook handling and reference-counted Vod housekeeping run as Sidekiq/Solid Queue
  jobs. Large forks may move to a background job if subtree size warrants it.
- Notifications via Noticed (in-app + email). Realtime (if needed) via Action Cable.

## 8. Security & tenancy guardrails

- Admin actions require server-side admin authorization on **every** action (ADR 0006).
- Tenant models must have a current tenant set; jobs/webhooks set it explicitly.
- Unique indexes on taxonomy (Category/Tag/Position names) are scoped by `workspace_id`.
- Forking never copies Axis-3 state; reference-counted Vod deletion protects shared media.

## 9. Where things live

```
app/
  controllers/        app/ (user app) + admin/ + auth/ + webhooks/aliyun
  frontend/           Inertia React pages, components (Vite)
  lib/ali_vod/        Aliyun VOD wrappers (ported)
  models/             Workspace, Video, Video::Segment, Note, Vod, Category, Tag,
                      Position, Technique, Progress, Share, Fork (+ concerns)
  policies/           Action Policy policies (Video::SegmentPolicy, …)
  services/           ForkService, Bjj::SeedTaxonomy, Youtube::Ingest, …
config/
  routes.rb + routes/ split by subdomain
docs/
  ARCHITECTURE.md  decisions/  roadmap/phases/  roadmap/iterations/  guides/
```

See `docs/roadmap/DEVELOPMENT_PLAN.md` for the build order and
`docs/roadmap/iterations/` for ongoing work.
