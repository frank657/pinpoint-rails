# Iteration 0007 — Notes mapped into segments (+ Video::Segment table rename)

> **Status:** 🚧 in progress · **Owner:** Frank · **Started:** 2026-06-17 · **Shipped:** —
> Links: **ADR 0011** (the locked mapping decisions + scenario contract) · ADR 0004
> (content/axes; numeric-seconds rule) · builds on 0005 (Video::Segment)
>
> **Locked visual + interaction spec (the build must match these):**
> - `docs/mockups/segments-notes-vertical-b.html` — the static all-scenarios timeline.
> - `docs/mockups/segments-notes-interactive.html` — the **interactive** prototype: it is the
>   reference for the mapping engine *and* the interactions — playhead-snapshot Start on the
>   add forms, "+ end time" stamp, untimed option, edit-mode toggle, drag between segments,
>   detach via the **"−" button or by dragging into a loose gap**, segment ⊢⊣ / note 📄 icons.
> - `docs/mockups/segments-notes-center-spine.html` — alternative explored (not the chosen layout).
>
> See `docs/guides/iteration-guide.md` (TDD loop) and `docs/guides/models-guide.md` (model rules).
> **Planning doc — do not code until agreed.**

---

## Preamble — questions answered first

### Q1 · Should the seconds be `float`, not `datetime`?
**Keep `float`.** These are **video timecodes** — an offset (duration) *into the media*, not a
point in wall-clock time. `datetime` would be semantically wrong (and break arithmetic like
"note.start − segment.start"). This is the ADR 0004 rule: *timestamps are numeric seconds
(floats), never formatted strings*. Audited every seconds column — all are already `float` and
correct:

| Column | Table | Type | Verdict |
|---|---|---|---|
| `start_seconds`, `end_seconds` | notes | float | ✓ keep |
| `start_seconds`, `end_seconds` | segments | float | ✓ keep |
| `resume_seconds` | progresses | float | ✓ keep |
| `duration_seconds` | videos | float | ✓ keep |

No migration. (Precision note: float-seconds is fine for player seeking; we are **not** moving
to integer-milliseconds — not worth the churn.)

### Q2 · Tables should follow model naming → rename `segments` → `video_segments`. Audit others.
**Agreed.** Convention (per the `Workspace::Membership` precedent and `models-guide.md`):
a namespaced model's table is its **full underscored name**, not the demodulized one. Audit of
every model:

| Model | Namespaced | Current table | Convention | Action |
|---|---|---|---|---|
| `Video::Segment` | yes | `segments` | `video_segments` | **RENAME** |
| `Workspace::Membership` | yes | `workspace_memberships` | `workspace_memberships` | ✓ already correct |
| `Tagging` | no | `taggings` | `taggings` | ✓ |
| `Video, Note, Category, Tag, Position, Technique, Progress, Share, Fork, Vod, Athlete, User, Workspace` | no | pluralized | same | ✓ |

So **only `Video::Segment`** is out of convention. This iteration renames it. (`models-guide.md`
currently says "table stays `segments`" — that guidance is **corrected** here: namespaced models
use the full underscored table name.)

> ⚠️ **Production-safety caveat (this is the one risky migration).** A table rename is *not*
> transparently zero-downtime: during a Dokku deploy the **old** release keeps serving for ~60s
> after migrations run, and it queries `segments` — which no longer exists → 500s on
> segment/video pages for that window. Options, in the build steps below: **(a)** accept the
> few-second window (single-user app, you won't be hitting segment pages mid-deploy) — recommended;
> **(b)** brief maintenance (`dokku ps:stop` → migrate → start); **(c)** backward-compat DB view
> (textbook zero-downtime, overkill here). Either way the migration is **reversible**.

---

## Goal & context

Make notes live **inside segments** on the video page (the design in
`segments-notes-vertical-b.html`): notes auto-map into the segment that contains them; users
re-organize by hand in an **edit mode**. The relationship is **stored** (`notes.segment_id`) so
manual placement sticks.

The bar: opening a video shows notes grouped under their segment cards exactly per the mockup;
turning on edit mode lets you drag a note into another segment or detach it; placements persist;
nothing reshuffles behind the user's back; and **publishing this does not break production**.

**Also in scope — the video Show note editor (Phase E).** While we're rebuilding the video page,
fix the note-editor gaps found in the audit:
- **Multiple positions & techniques — possible today, just no UI.** `Note` is already
  `has_and_belongs_to_many :positions` / `:techniques` (`note_positions` / `note_techniques`);
  `note_json` already returns arrays. Only a multi-select chip input is missing. **No schema change.**
- **Multiple categories — needs a model change.** `Note belongs_to :category` (a single
  `category_id`). To allow several, Category must become many-to-many (a `note_categories` join),
  aligning it with Tag/Position as a multi-value label (touches ADR 0004 — confirm).
- **Capture from the playhead** for both create flows (start prefilled from the current player
  time, editable; "+ end time" stamps the playhead) — per `docs/mockups/segments-notes-interactive.html`.

## Locked decisions (the model)

1. **`notes.segment_id`** (optional `belongs_to Video::Segment`). **Null = orphan** (auto-mappable).
   **Set = pinned** (locked — auto-map never touches it, however it got set).
2. **Auto-map adopts orphans only**, into **closed** (`[start, end]`) segments, by **`note.start`**:
   a timed orphan note is adopted by the closed segment where `seg.start ≤ note.start < seg.end`.
3. **Open-ended segments** (no `end_seconds`) have no range → **auto-map nothing**; reachable only
   by drag, or once an end is set (then they adopt orphans in range). **Not auto-closed.**
4. **Overlap of segments allowed.** Tiebreaker falls out of "pinned" + creation order: the first
   closed segment to cover a note adopts it, then it's locked. Residual (note *created* into an
   already-overlapping region): **earliest-created** covering segment wins.
5. **Gaps are real** — a timed note in a gap / before any segment stays orphan → shown **loose**.
6. **Untimed notes** (rich_text, no `start`) → orphan forever → **unanchored** group; drag-only.
7. **Sticky placement:** adoption fires only on a small set of events (below). Editing a note's
   time or a segment's range does **not** reshuffle already-pinned notes (no eviction; #11/#15 confirmed).
8. **Edit mode:** a toggle button. Available **only in edit mode**: drag a note between segments
   (re-pin), and detach it back to loose either via a per-note **detach button** (a "−") or by
   **dragging it into a loose gap** between segments. Detach sets `segment_id = null` (→ orphan)
   and does **not** re-adopt (no triggering event), so it sticks. (#14 — button *or* drag-to-loose.)
9. **`Video::Segment` table → `video_segments`** (Q2). Seconds stay `float` (Q1).

## The mapping spec (executable contract — every row becomes a test)

| # | Scenario | Required behavior |
|---|----------|-------------------|
| 1 | Note created, start in one closed segment | adopted → `segment_id` set |
| 2 | Note created, start in 2+ overlapping closed segments | adopt to **earliest-created** covering segment |
| 3 | Note created in a gap / before any segment | orphan → loose |
| 4 | Note has no timestamp (rich_text) | orphan → unanchored; never auto-mapped |
| 5 | Note start only under an open-ended segment | not adopted → orphan |
| 6 | Closed segment created over existing orphans | adopts those orphans |
| 7 | New segment overlaps another segment's notes | does **not** steal (pinned) → earlier keeps them |
| 8 | Open-ended segment created | adopts nothing |
| 9 | End set on open-ended segment | adopts orphan notes now in range |
| 10 | Closed segment end extended | adopts newly-covered orphans; pinned unaffected |
| 11 | Closed segment end shrunk | **no eviction** — pinned stay |
| 12 | Segment deleted | its notes → orphan (`nullify`); not auto-re-homed |
| 13 | Drag note into another segment (edit mode) | `segment_id` → target (pinned) |
| 14 | Detach — "−" button **or** drag into a loose gap between segments (edit mode) | `segment_id` → null (orphan); no re-adopt |
| 15 | Note `start_seconds` edited | pinned → stays; orphan → re-evaluate adoption |
| 16 | Pinned note whose time is outside its segment | allowed; sorts by `start_seconds` in the card |
| 20 | Fork a video | copied notes' `segment_id` relinks to the **copied** segments |

## Build steps

### Phase A — Data model + table rename (deploy-safe)
1. Migration `rename_segments_to_video_segments`: `rename_table :segments, :video_segments`
   (renames indexes too); set `Video::Segment.self.table_name = "video_segments"`. **Reversible.**
2. Migration `add_segment_to_notes`: `add_reference :notes, :segment, type: :uuid, null: true,
   foreign_key: { to_table: :video_segments, on_delete: :nullify }` + index `(segment_id)`.
3. Add `(video_id, start_seconds)` index to `video_segments` (consistency with notes; #Q gap).
4. Associations: `Note belongs_to :segment, class_name: "Video::Segment", optional: true`;
   `Video::Segment has_many :notes, dependent: :nullify` (FK already nullifies — keep both honest).
5. (Recommended refactor) extract a **`Timecoded` concern** shared by `Note` + `Video::Segment`:
   `start_seconds`/`end_seconds` shape, `end_after_start`, `range?`/`point?`, and a
   `covers?(seconds)` helper. Removes today's duplicated validation/scope.

### Phase B — Mapping engine
6. `Notes::SegmentMapper` service (pure, tested in isolation): `segment_for(note)` → the closed
   segment per rules #1/#2/#5 (earliest-created on overlap), or nil.
7. Triggers (thin callbacks delegating to the mapper — orphans only, never touch pinned):
   - `Note after_create` / `after_update of: start_seconds` → adopt if orphan + timed.
   - `Video::Segment after_create` / `after_update of: end_seconds` (incl. nil→value, extend) →
     adopt orphan timed notes now in range. No eviction on shrink.
   - Delete → FK `nullify` (no extra code).
8. Detach/move endpoint(s): extend `App::NotesController#update` to accept `segment_id`
   (set = pin/move, explicit null = detach), authorized (`:update?`), tenant-scoped. Moving/detaching
   does not trigger adoption.

### Phase C — Frontend (video Show timeline)
9. Props: video Show sends `notes` (with `segmentId`) + `segments`; group **server-side** into the
   structure the timeline needs (per-segment notes + loose + unanchored), reusing the mapper so UI
   and adoption agree.
10. Render the **Option B** timeline: segment cards (closed show `start–end`, **open-ended show
    `start →`**), notes nested by time, loose ghost rows, unanchored group.
11. **Edit mode toggle** (button). Off = read/seek only. On = drag notes between segment cards
    (PATCH `segment_id`); detach via a per-note **"−" detach button** *or* by **dragging into a
    loose gap** between segments (PATCH `segment_id = null`).
12. Keep click-to-seek on notes/segments in both modes.

### Phase D — Fork + docs
13. `ForkService`: thread an `old_segment_id → new_segment_id` map through the copy; set copied
    notes' `segment_id` from it (#20). Add to the fork spec. (Categories still aren't carried on
    fork — unchanged; fork already drops taxonomy.)
14. Update `models-guide.md` (namespaced-table rule correction; float-seconds reference) and
    `CLAUDE.md` if the table-naming rule needs restating.

### Phase E — Video Show note editor: multiplicity + playhead capture
15. **Multiple positions & techniques — UI only** (model already M:N). Add a multi-select chip
    input to the note editor (create + edit) for positions and techniques; controller permits
    `position_ids: []` / `technique_ids: []`; `note_json` already returns arrays.
16. **Multiple categories — model change.** Convert Category to many-to-many:
    - Migration: create `note_categories` (`note_id` uuid + `category_id` bigint, unique
      `[note_id, category_id]`); **backfill** existing `notes.category_id` → join rows; then
      `remove_column :notes, :category_id`. Reversible (down re-adds the column + backfills the
      first category).
    - `Note`: `belongs_to :category` → `has_and_belongs_to_many :categories, join_table: :note_categories`.
      Update `note_json` (`category` → `categories: []`), the note-editor UI (single → multi chip),
      and the Library **category filter** to array semantics. Permit `category_ids: []`.
17. **Capture from the playhead.** Opening the add-note / add-segment form **snapshots the current
    player time into Start** (editable — no live counter); a **"+ end time"** action stamps the
    current time (segment end / turns a point note into a range); an **untimed** option for
    rich-text notes. Matches `docs/mockups/segments-notes-interactive.html`.

## Test plan (write FIRST — TDD; the spec table drives it)

- **Model** (`spec/models/video/segment_spec.rb`, `note_spec.rb`): table is `video_segments`;
  `Note belongs_to :segment` optional; `Video::Segment has_many :notes`; `Timecoded` behavior.
- **Service** (`spec/services/notes/segment_mapper_spec.rb`): **one example per spec-table row
  #1–#12, #15, #16** — closed/open/gap/overlap/earliest-created/no-eviction, tenant-scoped.
- **Request** (`spec/requests/notes_spec.rb`): video Show groups notes under segments + loose +
  unanchored (assert the props); PATCH `segment_id` pins/moves; PATCH null detaches; authorization
  + tenant scoping (an outsider can't move a note).
- **Service** (`spec/services/fork_service_spec.rb`): forked notes relink to copied segments (#20).
- **System** (`spec/system/segment_timeline_spec.rb`, first system spec — stands up Capybara):
  edit mode → drag a note to another segment → reload → persisted; detach (the "−" button **and**
  dragging into a loose gap between segments) → note goes loose.
- **No-eviction guard**: editing a segment's end does not move pinned notes (#11) — explicit spec.
- **Multiplicity** (`spec/requests/notes_spec.rb` + model): a note accepts and returns **multiple**
  `position_ids`, `technique_ids`, and `category_ids`; `note_json` returns arrays for each.
- **Category migration** (`spec/models/note_spec.rb` / a migration spec): existing `category_id`
  data is backfilled into `note_categories` with **no loss**; the migration is reversible.
- **System**: on the video page, assign 2 positions + 2 categories to a note and reload → persisted.

## Exit criteria (strict)

- [ ] Every spec-table row (#1–#16, #20) has a passing test; behavior matches exactly.
- [ ] Video page renders the Option B timeline (closed + **open-ended** segments, loose,
      unanchored) matching `segments-notes-vertical-b.html`.
- [ ] Edit mode gates drag + detach; placements persist across reload; nothing reshuffles on note/segment edits.
- [ ] `Video::Segment` is backed by `video_segments`; `notes.segment_id` FK nullifies on segment delete.
- [ ] Fork relinks `segment_id` to copied segments.
- [ ] A note can have **multiple positions, techniques, and categories**, set from the video Show
      note editor; existing single categories migrated to `note_categories` with no loss.
- [ ] Add-note / add-segment forms **prefill Start from the player time** (editable) and support
      **"+ end time"** stamping; an untimed option exists for rich-text notes.
- [ ] **Green gate:** `bundle exec rspec` · `npm run check` (tsc) · `bin/vite build` · `bundle exec rubocop` — all clean.
- [ ] **Migrations are reversible** — `db:migrate` then `db:rollback` (3 steps) restores cleanly, verified locally.
- [ ] **Does not break production on publish** (your exit criterion):
  - Deploy to Dokku **succeeds** (build + boot + `db:prepare`), per the 0006-era pipeline.
  - **Post-deploy smoke test passes**: `/up` 200; load a video page; create a note; create a
    segment; verify mapping — on production.
  - The table-rename window is handled per **option (a)** (accept the few-second swap window).
  - **Rollback path documented**: `down` migrations + `dokku ps:rebuild`/previous release, in case.

## Build progress (2026-06-17)

**Done & green** (`rspec 154/0`, `tsc` clean, `vite build` ok, `rubocop` clean):
- Phase A — `video_segments` rename, `notes.segment_id` (FK nullify) + indexes, `Timecoded` concern.
- Phase B — `Notes::SegmentMapper` + model triggers; **every ADR 0011 scenario row #1–#16 has a
  passing spec** (`spec/services/notes/segment_mapper_spec.rb`), plus PATCH segment_id (drag/detach) request specs.
- Phase D — `ForkService` relinks copied notes to copied segments (#20, spec); docs updated.
- Phase E (backend + note editor) — Category is now **many-to-many** (`note_categories`, migrated
  with backfill); note editor assigns **multiple categories/positions/techniques**; create form
  snapshots the playhead into Start + "+ end time". Frontend updated for the `categories[]` prop.

## Build progress (2026-06-18) — Phase C + scope additions shipped

**Done & green** (`rspec 175/0`, `tsc` clean, `vite build` ok, `rubocop` clean), verified in-browser
against `docs/mockups/video-page-full.html` (headless-Chrome screenshots of the live `/videos/4`):

- **Unified video page** — `videos/Show.tsx` rebuilt: two-column grid (`1fr 392px`), the old
  `SegmentsEditor` + `NotesPanel` + top tags/athletes chip row are **removed/deleted**.
- **`TimelinePanel`** (new) — one panel: `+ Note at current time` (playhead-captured start, untimed,
  `+ end time`→range, searchable taxonomy pickers, body) · `+ Segment` form · `Organize` toggle ·
  time-ordered body (Unanchored section, segment cards with nested notes, loose notes, `⋯ gap ⋯`
  separators, empty states) · edit-mode drag between segments / drag-to-loose-gap, `−` detach,
  per-row `✎` inline editor + `🗑` delete. All persist via Inertia (`/notes`, `/segments`).
- **`VideoDetails`** (new) — read-first property list (Description + Categories/Positions/Techniques/
  Athletes/Tags): reads as chips, click a row to edit just that field, `Done` commits via
  `PATCH /videos/:id`; one field open at a time (auto-commits the previous).
- **`ChapterStrip`** (new) — segment blocks positioned by time + live playhead, click-to-seek.
- **`TokenPicker`** (new) — the searchable combobox (filter → dropdown → pill ×; tags/athletes
  create-on-Enter; athlete options/pills show avatars). **`AthleteAvatar`** = image or initials badge.
- **Backend** — `videos.description` (text, sanitized HTML); `video_categories`/`video_positions`/
  `video_techniques` HABTM joins (migration `20260618100000`, reversible); `Video` HABTM +
  inverse on Category/Position/Technique; `Athlete#initials` + `#avatar_hue`; `video_show_json`
  emits description + video taxonomy + athlete objects; `VideosController#update` permits
  `description` + `*_ids`. Specs: `athlete_spec` (initials/hue/avatar), `videos_spec`
  (taxonomy+description PATCH, show payload shape).

**Deferred to the UUID pass (iteration 0008) — same bigint-vs-uuid root cause:**
- **Athlete avatar IMAGE upload**: `active_storage_attachments.record_id` is `uuid`, Athlete is
  still bigint-keyed, so an image can't attach yet. `has_one_attached :avatar` is declared and the
  serializer reads it (returns nil → initials fallback, which is what the mockup shows). Wire up
  upload once Athlete is uuid.
- **Video description via Action Text**: same `record_id uuid` blocker, so the description is a
  plain sanitized-HTML `text` column (edited with Trix, rendered as HTML) rather than
  `has_rich_text`. Move to Action Text after 0008 if attachment support in the description is wanted.

**Decision on storage shape:** video taxonomy uses dedicated HABTM joins (parity with `note_*`),
**not** the single polymorphic taxonomy join floated in scope addition #5 — that consolidation
stays with the UUID work (it needs uniform key types to avoid the `Tagging` string-id workaround).

## Scope additions — from the full-page mockup review (2026-06-17)

The full video-page mockup (`docs/mockups/video-page-full.html`) is the agreed visual/interaction
spec for the Phase C rebuild. It pulled in these **confirmed** changes (to fold into the build):

1. **Unified video page** — one timeline panel (segment cards + notes + inline "+ Note"/"+ Segment"
   + Organize/drag/detach), replacing the split `SegmentsEditor` + flat `NotesPanel`. A
   **below-video** section holds the video's own attributes; the redundant top tags/athletes chip
   row is **removed**.
3. **Searchable token pickers** everywhere (filter → pill with ✕); tags & athletes are
   **create-on-Enter**, curated taxonomy is pick-existing.
4. **Video-level taxonomy** — videos get **categories, positions, techniques** (+ existing tags,
   athletes), enabling Library filters like "all videos in Closed Guard."
5. **Taxonomy goes polymorphic** (owner's call): one join per taxonomy shared by **Note and Video**
   (mirrors `Tagging`, which is already polymorphic) — replaces the per-type `note_categories` /
   `note_positions` / `note_techniques` with polymorphic equivalents. (Interacts with the 0008
   UUID pass — joins get touched either way.)
6. **Video rich-text `description`** — `has_rich_text :description` on Video (Action Text), like a
   note's body; shown/edited in the below-video section.
7. **Chapter strip** under the player — horizontal segment blocks + live playhead, click-to-seek;
   mirrors the vertical timeline.
8. **Read-first property layout** (replaces the always-open picker form). The below-video
   attribute block (description + categories/positions/techniques/athletes/tags) renders as a
   **read view** by default — each property is a row of value chips (or a muted `+ Add` /
   `+ Add description` affordance when empty). Clicking a row **opens just that one field** into
   its editor (searchable picker / rich-text box) with a **Done** button; clicking another row (or
   Done) commits the open field and closes it. Only one field is editable at a time. This is the
   Notion/Linear "property reads as text, click to edit" pattern — it stops the section from
   looking like a permanent form. (Mockup engine: `vid` state, `renderDetails`, `commitOpen`,
   `readChip`, `FK` map in `video-page-full.html`.) The note/segment inline editors keep their
   existing ✎-to-open-editor behavior — same principle (read by default, edit on intent).
9. **Athletes get avatars.** `Athlete has_one_attached :avatar`; render the avatar image wherever
   an athlete appears (read chips, picker pills, picker dropdown options). **Fallback when no
   avatar: a circular initials badge** derived from the name (1–2 letters), never a broken image.
   The athlete's **name always accompanies** the avatar (avatar + name, not avatar alone). Applies
   to the video's athlete property, note athlete chips, and the searchable athlete picker.

> These expand Phase C/E meaningfully (new polymorphic joins + video description + video taxonomy
> + Library filters + read-first property editing + athlete avatars). Worth a short ADR addendum
> (or ADR 0012 alongside UUID) since polymorphic taxonomy is an app-wide model decision.

## Out of scope (→ later)

- Reordering notes *within* a segment by hand (they stay time-ordered).
- A coach/athlete-style "all notes in this segment" cross-app query page.
- Bulk multi-select moves.
- Auto-closing open-ended segments / "extend to next" semantics (explicitly rejected — gaps are real).

## Confirmed before build
- **Table-rename downtime: option (a)** — accept the few-second window during the deploy swap
  (single-user app; reversible migration; covered by the production smoke test). ✓
- **`Timecoded` concern: in scope** (shared by Note + Video::Segment). ✓
- The behavioral model + scenario table are **locked in ADR 0011** — treat that as the contract.
