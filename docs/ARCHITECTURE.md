# Pinpoint — Architecture

> Read the ADRs in `docs/decisions/` first — they are the locked decisions this document
> elaborates. Where this doc and an ADR disagree, the ADR wins (and this doc is the bug).

## 1. What Pinpoint is

A video note-taking & learning platform. Upload videos (Aliyun VOD) or paste a YouTube
link; take **timestamped notes** (point or range) and **rich-text notes**; organize videos
into **Courses** and **Curriculums**; organize notes with **Categories**, **Tags**, and
**Folders**; **share** and **fork** anything; and study with a **learning layer**
(progress, spaced-repetition review, technique taxonomy, transcript/AI search).

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
            │  User ──< WorkspaceMembership >── Workspace        (global, NOT tenant)   │
            └──────────────────────────────────────────────────────────────────────────┘
                                   │ every model below is acts_as_tenant :workspace
   ┌───────────────────── AXIS 1: CONTENT (shared & forkable) ───────────────────────┐
   │  Video ──has_one── Vod (Aliyun)        Video ──< Segment                         │
   │    │  (source: upload | youtube)                                                 │
   │    ├──< CourseItem >── Course ──< Chapter                                         │
   │    │                      └──< CurriculumItem >── Curriculum                      │
   │    └──< Note                          Folder ──< Note                            │
   │  Note (timestamp point/range | rich_text; Action Text body; images via AS)       │
   └─────────────────────────────────────────────────────────────────────────────────┘
   ┌───────────────────── AXIS 2: TAXONOMY (labels, curated) ────────────────────────┐
   │  Category ──< Note      Tag ──<>── Note (join)                                   │
   │  Position ──< Technique(from_position,to_position,kind) ──<>── Note              │
   └─────────────────────────────────────────────────────────────────────────────────┘
   ┌───────────────────── AXIS 3: PER-USER STATE (private) ──────────────────────────┐
   │  Progress(user,workspace,item)   ReviewCard(user, note, FSRS state)             │
   └─────────────────────────────────────────────────────────────────────────────────┘
```

## 4. Canonical models

> This is the target model the phases build toward. Each phase introduces a slice. Naming
> here is binding; deviations need an ADR.

### Identity & tenancy (global — NOT acts_as_tenant)

- **User** — Devise login identity. `email`, `password`, `admin:boolean`. `has_many
  :workspace_memberships`, `has_many :workspaces, through:`. Has a `current_workspace`
  pointer (session-driven).
- **Workspace** — the tenant / "account for a topic" (ADR 0002). `name`, `slug`
  (FriendlyId). `has_many :workspace_memberships`, members through it.
- **WorkspaceMembership** — join (`user_id`, `workspace_id`, `role`). Role enables future
  multi-member workspaces (`owner`/`member`).

### Axis 1 — Content (acts_as_tenant :workspace)

- **Video** — a watchable item. `source:enum { upload, youtube }`, `title`,
  `duration_seconds:float`, `youtube_id` (nullable), `transcript` (later). For uploads,
  `has_one :vod`. Reusable across courses (join tables), forkable (ADR 0005).
- **Vod** — the Aliyun-backed media asset (ported, ADR 0007). `key` (Aliyun VideoId),
  `status:enum { uploading, uploaded, ready }`, `provider:enum { aliyun }`, `filename`,
  `duration`, `upload_expires_at`, `uploaded_at`, `ready_at`, `metadata:jsonb`. Has the
  `Vod::Providers` concern + `aliyun_uploader` / `aliyun_video`. **Reference-counted** by
  Videos (ADR 0005): destroy the Aliyun object only when the last Video referencing it is
  gone.
- **Segment** — a labeled time-range inside one Video. `video_id`, `start_seconds`,
  `end_seconds` (nullable → point), `title`, `position`. UUID.
- **Course** — ordered set of videos. `title`, `slug`, `description`.
- **Chapter** — optional section inside a Course grouping its items. `course_id`, `title`,
  `position`. UUID.
- **CourseItem** — `course_id`, `video_id`, `chapter_id` (nullable), `position`. The
  ordered join; a Video lives in many Courses.
- **Curriculum** — ordered set of Courses. `title`, `slug`, `description`.
- **CurriculumItem** — `curriculum_id`, `course_id`, `position`.
- **Note** — the heart of the app. UUID. `video_id` (nullable for standalone notes),
  `folder_id` (nullable), `category_id` (nullable), `note_type:enum { timestamp,
  rich_text }`, `start_seconds` (nullable), `end_seconds` (nullable → range),
  `chapter_id`(see ADR 0003 nuance), Action Text rich `body` (images via Active Storage
  direct upload), `title`. Owner-stamped; visibility per ADR 0005.
- **Folder** — note organization. `name`, `parent_id` (nullable, for nesting),
  `position`. `has_many :notes`.
- **Share** — view-grant (ADR 0005). polymorphic `shareable` (Note/Video/Course/
  Curriculum/Folder), `visibility:enum { private, unlisted, public }`, optional grantee.
- **Fork** — attribution back-reference (ADR 0005). `source_type/source_id`,
  `source_workspace_id`, `target_type/target_id`, `target_workspace_id`. No data coupling.

### Axis 2 — Taxonomy (acts_as_tenant :workspace)

- **Category** — user-defined, for notes. `name`, unique per workspace. `has_many :notes`.
- **Tag** — free-form. `name`, unique per workspace. `has_and_belongs_to_many :notes` (join
  `note_tags`).
- **Position** — BJJ taxonomy node (Phase 10). `name`, `category` (guard/pin/back/leg/…),
  `dominance` (dominant/neutral/inferior).
- **Technique** — typed edge between positions (Phase 10). `name`, `from_position_id`,
  `to_position_id`, `kind:enum { escape, sweep, pass, submission, transition, takedown }`.
  `has_and_belongs_to_many :notes`.

### Axis 3 — Per-user state (keyed by user + workspace; NEVER shared/forked)

- **Progress** — `user_id`, `workspace_id`, polymorphic `trackable` (Video/Course/…),
  `completed_at` (nullable), `resume_seconds` (for video resume), `last_viewed_at`.
- **ReviewCard** — FSRS card for a Note (Phase 8). `user_id`, `note_id`, `due_at`,
  `stability`, `difficulty`, `state`, `reps`, `lapses`, `last_reviewed_at`,
  `card_template` (one Note may have ≥1 cards, e.g. cloze). **No FSRS field ever on Note.**

## 5. Video ingestion (ported VOD pipeline + YouTube)

**Upload (Aliyun VOD):** unchanged from method-channel's proven flow —
1. Client creates a `Vod` → `after_create` calls Aliyun `CreateUploadVideo` →
2. server returns Base64 `upload_address` + `upload_auth` (STS creds) + a signed id →
3. browser uploads **directly to Aliyun OSS** →
4. Aliyun webhooks: `FileUploadComplete` → `status: uploaded`; `TranscodeComplete` →
   `status: ready` + `duration` + cover image. Playback via `GetPlayInfo` (m3u8).

**YouTube:** paste a link → extract `youtube_id` → fetch title/duration via oEmbed/metadata
→ create a `Video(source: youtube)`. No Vod, no upload. Player embeds YouTube; notes/segments
work identically against `*_seconds`.

The webhook controller runs **without a session** — it resolves the workspace from the
`Vod`/`Video` record and wraps tenant-scoped work in `ActsAsTenant.with_tenant` (ADR 0002).

## 6. Frontend (Inertia + React)

- Controllers render `render inertia: "Page", props: {...}`; pages live under
  `app/frontend/pages` (Vite). Shared layout per subdomain (app vs admin).
- The signature screen is the **video page**: player on one side, a time-synced notes
  timeline on the other; clicking a note seeks the player; creating a note captures the
  current `currentTime` as `start_seconds` (drag to set a range).
- Drag-to-reorder for CourseItems / Chapters / CurriculumItems / Folders.
- Rich-text notes use a React rich editor backed by Action Text; images go through Active
  Storage **direct upload** to Aliyun OSS.

## 7. Background jobs & realtime

- Aliyun webhook handling, deep-copy **fork** of large subtrees, transcript fetch, AI
  summarization, and FSRS due-date recomputation run as Sidekiq/Solid Queue jobs.
- Notifications via Noticed (in-app + email). Realtime (if needed) via Action Cable.

## 8. Security & tenancy guardrails

- Admin actions require server-side admin authorization on **every** action (ADR 0006).
- Tenant models must have a current tenant set; jobs/webhooks set it explicitly.
- Unique indexes on taxonomy (Category/Tag names) are scoped by `workspace_id`.
- Forking never copies Axis-3 state; reference-counted Vod deletion protects shared media.

## 9. Where things live (planned)

```
app/
  controllers/        app_subdomain + admin_subdomain controllers, webhooks/aliyun
  frontend/           Inertia React pages, components (Vite)
  lib/ali_vod/        Aliyun VOD wrappers (ported)
  services/vod_service/   Aliyun uploader + video info (ported)
  models/             Workspace, Video, Vod, Note, Course, ... (+ concerns)
  jobs/               fork copy, transcript, ai, vod housekeeping
config/
  routes.rb + routes/ split by subdomain
docs/
  ARCHITECTURE.md  decisions/  roadmap/phases/  guides/
```

See `docs/roadmap/DEVELOPMENT_PLAN.md` for the build order.
