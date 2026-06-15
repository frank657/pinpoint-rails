# Iteration 0005 — Athletes on videos

> **Status:** ✅ done · **Owner:** Frank · **Started:** 2026-06-15 · **Shipped:** 2026-06-15
> Links: ADR 0004 (three-axis — Athlete is Axis-2 taxonomy) · no mockup (data layer)
>
> See `docs/guides/iteration-guide.md` for how this document is structured and the TDD loop.

## Goal & context

Let a video record **who appears in it** — the coach(es)/athlete(s) featured. In BJJ the people
in an instructional are athletes either way, so we model a single role-agnostic **`Athlete`**
entity (no coach/athlete role distinction for now) with a **many-to-many** to `Video`.

`Athlete` is **Axis-2 taxonomy** (ADR 0004) — a curated, queryable entity like `Tag`/`Position`
(so "all videos featuring X" is a real query), workspace-scoped, unique name per workspace.

The bar: a Video can be associated with many Athletes and vice-versa, scoped per workspace,
matched-or-created by name like Tags — proven by specs.

## Locked decisions

1. **Entity = `Athlete`** (top-level, not nested — same as `Tag`/`Position`).
2. **Plain HABTM, no role.** Join table `video_athletes`; no coach/athlete role column.
3. **Modeled on `Tag`**: `acts_as_tenant :workspace`, `name` unique per workspace
   (case-insensitive), `Athlete.for_names` find-or-create helper.
4. **Data layer only this iteration.** Controller + video-page picker UI is a follow-up.

## Test plan (write these FIRST)

- **Model** (`spec/models/athlete_spec.rb`):
  - unique by name within a workspace (case-insensitive); same name allowed in another workspace.
  - `.for_names` finds-or-creates, de-duplicating case-insensitively (mirrors `Tag`).
  - HABTM both directions: `video.athletes << athlete` ⇒ `athlete.videos` includes the video.
  - tenancy: an Athlete in workspace A is not visible from workspace B.

## Build steps

1. Migration `create_athletes` (workspace ref, name, unique `[workspace_id, name]`).
2. Migration `create_video_athletes` (video + athlete refs, unique `[video_id, athlete_id]`).
3. `app/models/athlete.rb` — `acts_as_tenant`, validations, `for_names`, `has_and_belongs_to_many :videos`.
4. `app/models/video.rb` — `has_and_belongs_to_many :athletes, join_table: :video_athletes`.
5. Factory `spec/factories/athletes.rb`; the model spec above.

## Exit criteria

- [x] Video ⇄ Athlete many-to-many works both directions; scoped per workspace.
- [x] `Athlete` unique per workspace (case-insensitive); `Athlete.for_names` dedups.
- [x] `bundle exec rspec` green (incl. `spec/models/athlete_spec.rb`)
- [x] `npm run check` (tsc) clean
- [x] `bin/vite build` succeeds
- [x] `bundle exec rubocop` clean

## What shipped

- `app/models/athlete.rb` — Axis-2 taxonomy entity; `acts_as_tenant`, unique name per
  workspace (case-insensitive), `Athlete.for_names`, `has_and_belongs_to_many :videos`.
- `app/models/video.rb` — `has_and_belongs_to_many :athletes, join_table: :video_athletes`.
- Migrations `create_athletes` + `create_video_athletes` (unique `[video_id, athlete_id]`).
- `spec/models/athlete_spec.rb` (5 ex) + `spec/factories/athletes.rb`.
- Result: rspec 107/0, tsc clean, vite build ok, rubocop clean.

## Out of scope (→ follow-up)

- Controller + video-page athlete picker (tag-style input), an athletes index/show page
  ("all videos featuring X", like `positions/Show`), and carrying athletes on fork.
- A coach/athlete **role** (deferred — revisit if the distinction is needed).
- Athlete attributes (belt, team, …).
