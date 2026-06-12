# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What Pinpoint is

Pinpoint is a **video note-taking & learning platform**. You upload videos (to Aliyun VOD)
or paste a YouTube link, then take **timestamped notes** (point or time-range) on them,
organize videos into **Notebooks** (each a set of videos in **Chapters**, plus the notes you
take on them), label notes with **Categories** and **Tags**, and **share / fork** any of it
to other users. A **learning layer** (progress, spaced-repetition review, a technique
taxonomy, and transcript/AI search) sits on top.

> **Content model = Notebook** (ADR 0010, supersedes 0003): `Notebook → Notebook::Chapter →
> Notebook::Item → Video`. The old **Course / Curriculum / Folder** concepts were removed —
> don't reintroduce them.

The author's primary use case is **BJJ (Brazilian Jiu-Jitsu)** instructional study, but the
product is general-purpose for **any** kind of video learning. Keep the core domain
generic; keep BJJ-specific affordances (positions/techniques) in clearly
separable modules.

## Project Documents

Before starting work, check relevant documents:
- `docs/ARCHITECTURE.md` — full architecture + the canonical data model
- `docs/roadmap/DEVELOPMENT_PLAN.md` — the phase-by-phase plan and current status
- `docs/roadmap/phases/` — one file per development phase (we build phase by phase)
- `docs/decisions/` — Architecture Decision Records (ADRs): the **locked** decisions. Read
  before changing tenancy, the content model, sharing/forking, or the subdomain layout.
- `docs/SETUP_CREDENTIALS.md` — the running checklist of secrets/config the **user** must
  provide (Aliyun OSS/VOD, optional YouTube API key, deploy env). Update it as new
  integrations are added.
- `docs/guides/` — area guides (added as the corresponding subsystem is built)

**Rule:** the ADRs in `docs/decisions/` are locked. Do not contradict an accepted ADR in
code. To change one, write a new ADR that supersedes it (see `docs/decisions/README.md`).

## Tech Stack

- Ruby 3.3.2, Rails 8.1.3 — **monolith** (NOT API-only). See ADR 0001.
- **Inertia.js + React + Vite** for the frontend (`inertia_rails`, `vite_rails`)
- PostgreSQL (multi-database: primary, queue, cache, cable)
- Solid Cache / Solid Queue / Solid Cable; Sidekiq + Sidekiq Cron for jobs
- **Devise** (session-based — no JWT; see ADR 0001), **Action Policy** (authorization; ADR 0008)
- **acts_as_tenant** — multi-tenancy scoped to **Workspace** (see ADR 0002)
- Aliyun OSS (Active Storage) + Aliyun VOD (video) — ported from method-channel (ADR 0007)
- Active Storage **direct upload** (images in rich-text notes, cover images)
- FriendlyId (slugs), pg_search (full-text), Kaminari (pagination)
- Noticed (notifications), PaperTrail (audit), Mobility (i18n: en/zh)
- Tailwind CSS, Kamal + Thruster (deployment)

## Subdomain layout (see ADR 0006)

- `pinpoint.com` — marketing / landing (public)
- `app.pinpoint.com` — the authenticated user app (Inertia + React)
- `admin.pinpoint.com` — the admin panel (Inertia + React, admin-only)

Routes are split by subdomain constraint in `config/routes.rb` / `config/routes/`.

## The three-axis model (see ADR 0004 — internalize this)

Keep these three concerns in **separate tables**; do not entangle them:
1. **Content** (shared & forkable): Video, Vod, Segment, Notebook, Notebook::Chapter,
   Notebook::Item, Note.
2. **Taxonomy** (labels/curated): Category, Tag, Position, Technique.
3. **Per-user state** (never shared, always private): Progress, ReviewCard.

When forking, deep-copy **content**; re-point **taxonomy** into the forker's workspace;
**never** copy per-user state. Timestamps are stored as **numeric seconds** (floats), never
formatted strings; notes support an optional `[start_seconds, end_seconds]` range.

## Common Commands

```bash
# Development
bin/dev                              # Start Rails + Vite (Procfile.dev)
bin/rails c                          # Rails console

# Database
bin/rails db:create db:migrate db:seed
bin/rails db:migrate

# Tests (RSpec — see docs/guides/testing-guide.md once written)
bundle exec rspec
bundle exec rspec spec/models/note_spec.rb
bundle exec rspec spec/models/note_spec.rb:42

# Background jobs
bundle exec sidekiq

# Frontend
bin/vite dev                         # Vite dev server (usually via bin/dev)
```

## Key Rules (Quick Reference)

**Models & controllers — namespace by domain:**
- Nest related models under a parent: `Workspace::Membership`, `Video::Segment`, etc. (not
  `WorkspaceMembership`). Because the parent (e.g. `Workspace`) is itself a table, nested
  models set `self.table_name = "workspace_memberships"` explicitly (don't use
  `table_name_prefix` — it also rewrites the parent's own table).
- Controllers are namespaced by surface (`App::`, `Admin::`, `Auth::`, `Landing::`,
  `Webhooks::`), and by resource where nested.

**Tenancy:**
- Every workspace-owned model uses `acts_as_tenant :workspace`. Never query a tenant model
  without a current tenant set (set it from the session/subdomain in a `before_action`).

**Controllers:**
- Inertia actions render with `render inertia: "Page/Name", props: {...}`.
- Use bang methods (`save!`, `update!`, `destroy!`); a base controller rescues globally.
- Authorize with Action Policy: `authorize! record, to: :rule?` (policies in `app/policies/`).

**Content vs. state:**
- Before adding a column, decide which of the three axes it belongs to. Per-user state
  never goes on a content table.

**Testing:**
- Stub Aliyun VOD and any AI/transcript provider in specs — never hit the network.

## Toolchain

- Pinned via `.tool-versions` (asdf): **Ruby 3.3.2, Node 22.22.3**. Node ≥20.19/≥22.12 is
  required by Vite 8 / rolldown — 20.16 silently skips the native binding. CI uses Node 22.

## Database

- Development: `pinpoint_rails_development`
- Test: `pinpoint_rails_test`
- Staging/Production: via `DATABASE_URL`
- Multi-database: primary, queue (Solid Queue), cache (Solid Cache), cable (Solid Cable) —
  each env has all four DBs (`*_cache`, `*_queue`, `*_cable`).

## Deployment

Kamal + Docker (multi-stage, Ruby 3.3.2-slim). See `docs/DEPLOY_CHECKLIST.md` (added in
Phase 0). `SOLID_QUEUE_IN_PUMA` runs jobs in the web process for single-server setups.
