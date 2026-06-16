# Iteration 0006 — Polymorphic tagging, Library v2, taxonomy & segment UI, athletes (epic)

> **Status:** ✅ shipped (0006a–f) · **Owner:** Frank · **Started:** 2026-06-15 · **Shipped:** 2026-06-16
> Links: ADR 0004 (tags/positions/athletes are Axis-2 taxonomy) · builds on iteration 0005
> (Athlete model) · Mockup: none (owner opted out)
>
> See `docs/guides/iteration-guide.md` for structure + the TDD loop.
>
> **⚠️ This is an epic — larger than one normal iteration.** It MUST start with the
> **Research & detailed planning** phase below and produce an agreed build plan (and likely
> sub-iteration docs) **before any code is written**. Do not code from this doc directly.

## Goal & context

The Library (`/videos`) and the tagging story are thin. The owner wants the app to actually be
browsable and organizable. This epic closes the main UI gaps found in the 0005 follow-up audit
and reworks tagging to be first-class across content types.

Scope (eight areas):

1. **Polymorphic tags.** Today `Tag` is HABTM `Note` only (`note_tags`). Make tagging
   **polymorphic** so the same `Tag` can be applied to **Notes and Videos** (and more later).
2. **Video tags.** Tag videos directly (via the polymorphic mechanism) — shown on cards and
   usable as a filter. (This is the "tags" the owner meant — distinct from athletes.)
3. **Note tagging UI — positions & techniques.** `note_positions`/`note_techniques` joins exist
   but there is **no UI** to tag a note with a Position/Technique. Add it. (Free-text tags
   already work in `NotesPanel`; this adds the curated-taxonomy tagging.)
4. **Segment add/edit/delete UI** on the video page (CRUD exists server-side; UI only shows
   seek-chips today).
5. **Category & Tag management** — dedicated pages to create/rename/merge/delete categories and
   tags (controllers exist; no management surface today).
6. **Athletes UI.** Assign athletes to a video; an **Athletes** sidebar entry; an athlete
   **show page** listing every video featuring them (like `positions/Show`).
7. **Library v2.** Rich video cards (poster, added date, duration, athlete chips, tag chips,
   note count) + filters (added-date range, tag, athlete, source).
8. **Global search.** Extend the ⌘K spotlight (`SearchController`) to also return **videos**
   (by title, tag, athlete) — not just notes.

The bar: tags work uniformly on notes and videos; the Library is a real browsable shelf with
filters/search; notes can be tagged with positions/techniques (so the Phase-10 graph can
finally be populated from the UI); segments are editable; athletes are first-class.

## Research & detailed planning — REQUIRED before any code

The owner's instruction: **research the best UI/UX for this app first, and plan each feature
out properly before building.** This phase is a gate. Its output is an agreed, concrete plan
(appended here and/or split into sub-iteration docs). Coding starts only after sign-off.

### A. UI/UX research (deliverable: a short "direction" write-up per surface)

Research patterns that fit **this** app — Tatami theme (warm cream/ember), Inertia + React,
and the conventions already in the codebase — rather than importing generic patterns. Anchor
on what already exists:
- The **tag-style chip input** already used for note tags in `NotesPanel` (reuse/extract it as
  a shared `TagInput`/`TokenInput` component for notes, videos, athletes, positions).
- The **filter pattern** in `Search.tsx` / `SearchSpotlight.tsx` (server round-trip via
  `router.get(..., { preserveState })`) — reuse for the Library filter bar.
- The **aggregation show page** pattern in `positions/Show.tsx` (reuse for `athletes/Show`).
- Reference products to study for the *card grid + filter rail + chip tagging* UX (Snipd /
  Recall / YouTube library / Notion database views) — capture 2–3 concrete takeaways each, not
  a generic survey. Decide: filter **rail vs top bar**; chips vs dropdowns; inline-create vs
  modal for new tags/categories/athletes.
- Decide the **management page** shape (categories/tags): simple table with inline
  rename/delete + merge action.

### B. Data-model design (the load-bearing decision — resolve before coding)

**Polymorphic tagging across a UUID and a bigint table.** `notes.id` is **UUID**;
`videos.id` is **bigint**. A single polymorphic `taggings.taggable_id` column cannot be both.
Pick and justify one:
  - **(i) `taggable_id` as `string`** + `taggable_type` — one `taggings` table, app-level
    association; loses a real FK and mixes id formats. Simplest schema, most flexible.
  - **(ii) Per-type join tables** (`note_tags` kept + new `video_tags`) — typed and FK-clean,
    but not "polymorphic" and duplicates wiring. (Closest to today.)
  - **(iii) Standardize ids** (give Video a UUID, or a separate taggable surrogate key) — most
    invasive; probably overkill.
  - Recommendation to validate: **(i)** for true polymorphism as the owner asked, *unless* the
    planning phase decides FK integrity matters more, then **(ii)**.
- Also decide: is `Tagging` `acts_as_tenant :workspace`? (Yes — keep taggings workspace-scoped.)
  Uniqueness `[tag_id, taggable_type, taggable_id]`. **Migration of existing `note_tags`** data
  into the new structure (backfill + drop), reversible.
- Confirm whether **Category** also becomes polymorphic/video-applicable, or stays note-only.
  (Default: Category stays note-only; only Tag goes polymorphic.)

### C. Per-area build plan + sequencing

Produce an ordered plan. Recommended phasing (each likely its own sub-iteration doc so PRs stay
reviewable — this epic spawns them):

- **0006a — Polymorphic tagging foundation:** `Tagging` model + migration + `note_tags`
  backfill; `Note`/`Video` `has_many :tags`; `Tag` management page; keep existing note tag UI
  working. (Unblocks video tags + library tag filter.)
- **0006b — Library v2:** enriched `video_json` (poster, athletes, tags, date, duration, note
  count) + `videos#index` filters/search + the new card grid & filter bar.
- **0006c — Athletes UI:** assign-to-video picker, Athletes nav, `athletes/Show`.
- **0006d — Note position/technique tagging UI** (+ reuse the shared chip input).
- **0006e — Segment add/edit/delete UI** on the video page.
- **0006f — Category management page** + global ⌘K search extended to videos.

(Order is a recommendation; the planning phase finalizes it. 0006a is a hard prerequisite for
the video-tag parts of 0006b.)

## Locked decisions (from the owner)

1. **Tags belong on videos directly** (not derived from notes), and **tagging is polymorphic**
   — one `Tag`, applied to Notes and Videos (design per §B).
2. **No mockup** — but a written UI/UX direction (per §A) is required before building.
3. **Extend global search** to include videos.
4. **Athletes get a sidebar entry and a show page** listing their videos; athletes are
   assignable to a video from the video page.
5. **Add the audited gaps:** note position/technique tagging, segment add/edit UI, and
   category/tag management — all in this epic.
6. **Plan-before-build is mandatory** (the §Research phase gates all coding).

## Open questions (confirm during planning)

- **"Tag a note"** — interpreted as adding **Position/Technique** tagging UI to notes (free-text
  tags already exist). Confirm that's what you meant (vs. something about the polymorphic free
  tags on notes).
- **Polymorphic id strategy** — (i) string `taggable_id` vs (ii) per-type join tables (§B).
- **Category scope** — stays note-only, or also applies to videos?
- A coach/athlete **role** is still deferred (from 0005) unless you want it now.

## Test plan (write FIRST, per sub-iteration — TDD)

High level; each sub-iteration spells out its own:
- **Model:** `Tagging` polymorphic associations + tenancy + uniqueness; `Tag` applied to a Note
  and a Video; `Tag` merge logic; `Video` scopes (`featuring`, `with_tag`, `added_between`,
  `from_source`, `search`).
- **Request:** `videos#index` enriched props + each filter + `q` (title/tag/athlete),
  tenant-scoped; tag attach/detach on notes & videos; note position/technique attach/detach;
  segment create/update/destroy from the page; category/tag management CRUD + merge; athletes
  `show` lists videos; global `search#query` returns video hits.
- **System (Capybara — first system spec, stands up the harness):** tag a video and filter the
  Library by that tag; assign an athlete and open the athlete page; tag a note with a position;
  add a segment on the video page.

## Exit criteria (epic-level; each sub-iteration carries its own slice + the gate)

- [x] Research/UX direction written and agreed; data-model design (§B) decided and recorded
      (option (i), string `taggable_id` — recorded in `0006a`).
- [x] Polymorphic tags: a `Tag` applies to both Notes and Videos; existing note tags migrated
      with no loss; tag management page (create/rename/merge/delete).
- [x] Library v2: rich cards + filters (added-date range, tag, athlete, source) + search, all
      server-side and tenant-scoped.
- [x] Notes can be tagged with positions/techniques from the UI; segments are add/edit/delete
      from the video page; categories are manageable.
- [x] Athletes: assignable to a video, Athletes nav entry, athlete show page with their videos.
- [x] Global ⌘K search returns videos (title/tag/athlete) as well as notes.
- [x] Per sub-iteration: `bundle exec rspec` green (136 examples), `npm run check` clean,
      `bin/vite build` ok, `bundle exec rubocop` clean (180 files).
- [ ] System (Capybara) specs — deferred: the browser-driver harness isn't available in the
      build environment; the Inertia/React seams are covered by request specs + `tsc`/`vite build`.

## What shipped

- **0006a — Polymorphic tagging foundation** (see `0006a-polymorphic-tagging-foundation.md`):
  `taggings` table (string `taggable_id`, option (i)) + `Tagging` model + `Taggable` concern on
  `Note`/`Video`; reversible `note_tags` → `taggings` migration; `Tag#merge_into!`/`usage_count`;
  Tag management page (create/rename/merge/delete) + **Tags** sidebar entry; `video_json` carries
  tags. Existing note-tag UI + filter preserved.
- **0006b — Library v2:** `Video` scopes (`search`, `from_source`, `featuring`, `with_tag`,
  `added_between`); enriched `videos#index` (poster, note count, athletes, tags, date, duration)
  with server-side tag/athlete/source/date/title filters; new card-grid Library + filter bar;
  `videos#update` assigns tags & athletes.
- **0006c — Athletes UI:** `AthletesController` (index + show + create) + `AthletePolicy`;
  **Athletes** sidebar entry; `athletes/Index` and `athletes/Show` (videos featuring them);
  reusable `TokenInput`; inline tag/athlete editor on the video page.
- **0006d — Note position/technique tagging UI:** `note_json` carries positions/techniques;
  `TaxonomyPicker` in the new-note form + per-note `NoteTaxonomyEditor` (PATCH) so the graph is
  populatable from the UI.
- **0006e — Segment add/edit/delete UI:** `SegmentsEditor` on the video page over the existing
  CRUD (add at current time, rename/retime, delete, seek).
- **0006f — Category management + search-over-videos:** `Category#usage_count`/`merge_into!`;
  category management page (create/rename/merge/delete) + **Categories** sidebar entry; ⌘K
  spotlight + full search page now return videos (title/tag/athlete) alongside notes.

## Out of scope (→ later)

- Pagination/infinite scroll on the Library (add Kaminari when the list grows).
- Carrying tags/athletes over on **fork** (revisit with the taxonomy-on-fork decision, ADR 0005).
- Coach/athlete **role** (still deferred from 0005).
- Bulk operations (multi-select tag/delete) on the Library.
