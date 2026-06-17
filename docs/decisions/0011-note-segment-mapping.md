# ADR 0011 — Notes mapped into segments (stored association, orphan/pinned)

- **Status:** Accepted
- **Date:** 2026-06-17
- **Decision owner:** Frank Zhu

---

## Context

A video carries two time-anchored things (both Axis-1 content, ADR 0004):

- **`Video::Segment`** — a *structural* chapter: a labelled time-range that divides the video.
- **`Note`** — *authored content* at a timestamp or range (rich body, tags, category,
  positions/techniques, shareable, searchable).

The product shows notes **grouped within the segment that contains them** (see
`docs/mockups/segments-notes-vertical-b.html`), and lets users **reorganize by hand**. We had to
decide: (1) should Note and Segment be one model? (2) is a note's segment **derived** on read or
**stored**? (3) the exact behavior across overlaps, open-ended segments, gaps, edits, and forks.

## Decision

1. **Keep `Note` and `Video::Segment` as separate models.** They share a "time-range on a video"
   *shape* but are different *kinds* — structure vs. content — with different attributes and
   lifecycles. The containment UI itself needs two tiers (a container and the contained). Shared
   time-range behaviour is factored into a **`Timecoded` concern** (start/end seconds,
   `end_after_start`, `range?`/`point?`, `covers?`).

2. **The association is STORED** on `notes.segment_id` (optional `belongs_to`). **Null = orphan**
   (auto-mappable). **Set = pinned** (locked — auto-map never moves it, however it was set).
   Stored (not derived) because manual drag-drop override *requires* a persisted choice, and we
   want segment membership to be a first-class, queryable column.

3. **Auto-map adopts orphans only**, into **closed** (`[start, end]`) segments, by **`note.start`**:
   a timed orphan is adopted by the closed segment where `seg.start ≤ note.start < seg.end`.
   - **Open-ended segments** (no `end`) have no range → auto-map nothing (drag-only until an end is set).
   - **Overlap allowed**; the **first / earliest-created** covering segment adopts the note, then
     it's pinned, so later overlapping segments skip it.
   - **Gaps are real** → a timed note in a gap stays orphan → shown **loose**.
   - **Untimed notes** (no `start`) → orphan forever → **unanchored**.

4. **Adoption is event-driven and never evicts.** It runs on: note create; note `start_seconds`
   edit *while orphan*; segment create (closed); segment `end` set-or-extend. Editing a note's
   time or a segment's range never moves an already-**pinned** note. **Placement is sticky** —
   set once, then user-managed.

5. **Manual reorganization via an edit-mode toggle:** drag a note between segment cards (re-pin),
   and detach it back to loose either with a per-note **detach button** (a "−") or by **dragging it
   into a loose gap** between segments (both set `segment_id = null`). Detaching does not re-adopt.

6. Seconds are **`float` timecodes** (offsets into the media, not wall-clock — ADR 0004). The
   segment table is **`video_segments`** (namespaced-model naming convention).

### The scenario contract (locked)

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

## Consequences

- ✅ Manual placement persists (drag-drop is possible because the choice is stored).
- ✅ Overlap is safe: pinning + creation-order resolves ownership, and the user can override.
- ✅ Open-ended / gap / untimed / straddle / span all fall out of the one `note.start` rule;
  straddle/span are purely cosmetic in the UI (the note lives in one segment).
- ⚠️ The stored column must be maintained on the listed events (a `Notes::SegmentMapper` service).
  Mitigated by **orphans-only adoption** (pinned notes are never re-evaluated) → few triggers,
  no eviction logic.
- ⚠️ Editing a note's time or a segment's range will **not** re-chapter already-placed notes.
  Intentional and predictable; the user moves them by hand.
- ⚠️ `ForkService` must relink `segment_id` to the copied segments (otherwise it dangles).

## Alternatives considered

- **Derive containment on read (no stored column).** Rejected — cannot support manual drag-drop
  override (you can't override a pure derivation).
- **Hybrid: derive the default, store only an override "pin".** Considered; rejected in favour of
  full storage so segment membership is a single, queryable source of truth (and because the
  orphans-only rule already keeps the maintenance small).
- **Combine `Note` + `Video::Segment` into one model (kind enum / STI).** Rejected — different
  roles/attributes/lifecycle; would bloat one table with mostly-null columns and force
  `where(kind: …)` across every notes query; the containment UI needs two distinct tiers.
- **Auto-close open-ended segments / "extend to next chapter" semantics.** Rejected — the product
  wants real gaps; open-ended means "no auto range" until an end is set.
- **Forbid overlapping segments.** Rejected — overlap is allowed and made safe by pinning + override.

## Sources

- Implementation plan + test plan: `docs/roadmap/iterations/0007-note-segment-mapping.md`.
- UX exploration: `docs/mockups/segments-notes-vertical-b.html`.
