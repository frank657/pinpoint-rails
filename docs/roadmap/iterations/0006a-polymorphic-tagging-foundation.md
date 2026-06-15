# Iteration 0006a — Polymorphic tagging foundation

> **Status:** 🛠️ in progress · **Owner:** Frank · **Started:** 2026-06-15 · **Shipped:** —
> Parent epic: `0006-tagging-library-and-taxonomy-ui.md` (§C, first sub-iteration).
> Links: ADR 0004 (Tag is Axis-2 taxonomy) · this is the hard prerequisite for the video-tag
> parts of 0006b and the Library tag filter.

## Goal & context

Make tagging **polymorphic** so a single `Tag` can be applied to **Notes and Videos** (and more
content types later), and give tags a real **management surface**. Today `Tag` is a HABTM of
`Note` only (`note_tags`); there is no way to tag a video and no way to rename/merge/delete tags.

This sub-iteration delivers the data-model foundation + a Tag management page, while keeping the
existing note-tagging UI working with no behaviour change.

## Data-model decision (epic §B — resolved)

**Option (i): one `taggings` table keyed by a string `taggable_id` + `taggable_type`.**

`notes.id` is **UUID** and `videos.id` is **bigint**, so a single polymorphic id column cannot be
a real FK to both. We store `taggable_id` as a **string** and resolve the association at the app
layer. This matches the pattern already established in the codebase by `Fork`/`Share`
(`target_id: id.to_s`, polymorphic `shareable`). Trade-off: no DB FK on the taggable side, and
`Model.joins(:tags)` can't be used (varchar vs uuid/bigint mismatch) — reads go through the
preloaded association and filters use a casted subquery (`id::text IN (...)`).

- `Tagging` is `acts_as_tenant :workspace` (workspace-scoped, like all Axis-2 taxonomy joins).
- Uniqueness: `[tag_id, taggable_type, taggable_id]` (DB unique index + model validation).
- Existing `note_tags` data is **backfilled** into `taggings` and the table is dropped; the
  migration is reversible.
- **Category stays note-only** (epic default); only `Tag` goes polymorphic.

## What shipped

- `taggings` table (string `taggable_id`), `Tagging` model, `Taggable` concern
  (`has_many :tags`, `tag_names=` setter) included into `Note` and `Video`.
- `Tag#merge_into!` + `Tag#usage_count`; reversible `note_tags` → `taggings` migration.
- `App::TagsController` full CRUD + `merge`; `tags/Index.tsx` management page; **Tags** sidebar
  entry. Note tag create/read/filter preserved (filter rewritten to a casted subquery).
- `video_json` now carries `tags`, proving the polymorphic association on Videos.

## Test plan (TDD — written first)

- **Model (`Tagging`, `Tag`, `Taggable`):** polymorphic association + tenancy + uniqueness; the
  same `Tag` applied to a Note **and** a Video; `tag_names=` find-or-create; `merge_into!`
  de-dups and deletes the source.
- **Request (`tags#*`):** index renders enriched props (name + count), tenant-scoped; create /
  rename / delete / merge; note create-with-tags + tag filter still work; `videos#show` exposes
  `tags`.

## Exit criteria

- [x] Data-model design recorded (above).
- [x] A `Tag` applies to both Notes and Videos; existing note tags migrated with no loss.
- [x] Tag management page: create / rename / merge / delete.
- [x] Existing note tag UI + filter unchanged in behaviour.
- [x] `bundle exec rspec` green, `npm run check` clean, `bin/vite build` ok, `bundle exec rubocop` clean.

## Out of scope (→ later sub-iterations)

- Video tag **editing UI** + Library tag filter/cards (0006b).
- Note position/technique tagging UI (0006d); segment CRUD UI (0006e).
- Carrying tags over on fork (ADR 0005).
