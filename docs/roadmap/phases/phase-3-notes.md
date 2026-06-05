# Phase 3 — Notes, categories, tags, segments

**Goal:** the core note-taking experience. On a video, create **timestamped notes** (a
point or a `[start, end]` range) and **rich-text notes** (Action Text body with
direct-upload images). Organize them with user-defined **Categories** and free-form
**Tags**. Mark **Segments** (labeled time-ranges) on a video.

**Depends on:** Phase 2 · **Locked by:** ADR 0004 (three-axis model)

## Scope

### Note (Axis 1 — content)
- `Note` (acts_as_tenant, UUID): `video_id` (nullable for standalone notes),
  `note_type:enum { timestamp, rich_text }`, `start_seconds:float` (nullable),
  `end_seconds:float` (nullable → range vs point), `title`, `category_id` (nullable),
  `folder_id` (nullable; Folder model lands in Phase 4 — column reserved or added then),
  Action Text rich `body`.
- **Timestamps are numeric seconds, never strings** (ADR 0004). Range when `end_seconds`
  present; point otherwise.
- Rich-text notes embed images via Active Storage **direct upload** to Aliyun OSS (the
  Phase 0/2 direct-upload plumbing).
- PaperTrail on Note for edit history/undo (ADR 0007 opt-in).

### Categories & Tags (Axis 2 — taxonomy)
- `Category` (acts_as_tenant): `name`, **unique per workspace**. Users create their own.
- `Tag` (acts_as_tenant): `name`, unique per workspace; `note_tags` join. Tag input with
  autocomplete; create-on-the-fly.
- Keep these **separate** from the BJJ Position/Technique taxonomy (Phase 10) — different
  axis, different table (ADR 0004).

### Segment (Axis 1 — content)
- `Segment` (acts_as_tenant, UUID): `video_id`, `start_seconds`, `end_seconds` (nullable),
  `title`, `position`. The in-video labeled-range / clip concept (distinct from Course
  "Chapter", ADR 0003).

### Frontend (the signature screen)
- Video page: **player + time-synced notes panel**. Creating a note captures the player's
  `currentTime` as `start_seconds`; drag/scrub to set `end_seconds` (range). Clicking a
  note seeks the player. Notes render on the scrubber as markers.
- Rich-text editor for `rich_text` notes (full-page, images, etc.).
- Category picker + tag input on a note; filter the notes panel by category/tag.
- Segment editor on the timeline.

## Key tasks
1. `Note` model + Action Text + direct-upload images + PaperTrail; factories/specs.
2. `Category`, `Tag` (+ `note_tags`) with per-workspace uniqueness; CRUD + autocomplete.
3. `Segment` model + timeline UI.
4. Notes panel synced to player (seek on click, capture time on create, range drag).
5. Rich-text note editor + image direct upload.
6. Filtering notes by category/tag; pg_search over note title/body.

## Out of scope
- Folders & course/curriculum organization (Phase 4 — `folder_id` reserved here).
- Spaced-repetition review of notes (Phase 8 — ReviewCard is Axis 3, not built here).
- Position/technique tagging (Phase 10).

## Exit criteria
- On a video, create a point note and a range note; both seek correctly and show on the
  scrubber.
- Create a rich-text note with an inline image (image lands in Aliyun via direct upload).
- Create a Category and a couple of Tags (workspace-unique); assign to notes; filter by them.
- Mark a Segment with a label and range; it renders on the timeline.
- Editing a note records a PaperTrail version; timestamps are stored as numeric seconds
  (spec asserts no string formatting in the column).
