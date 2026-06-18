# Iteration 0010 — Quick-capture footer + video-page cleanup

> **Status:** ✅ Shipped · **Owner:** Frank · **Started/Shipped:** 2026-06-18
>
> Implements the quick-capture footer designed in `docs/mockups/260618-video-page-full.html`
> (**Version A** — the expandable "Details" variant; B = `…-inline.html` is the rejected-for-now
> alternative). Frontend-only: the `POST /notes` endpoint already accepts start/end + taxonomy.
>
> **Done:** new `QuickCapture.tsx` fixed footer (blank-until-focus start, left start cluster /
> right end cluster with its own "⟲ now", inline Add, ⌘⏎ add / ⌘↑ Details). `TimelinePanel` head
> reduced to `+ Segment` (primary) + Organize. `VideoDetails` description moved below tags.
> `ChapterStrip` removed. Verified on the live page (`/videos/:id`) against the mockup via headless
> browser, incl. an end-to-end add (0→1 note via ⌘⏎, appears in timeline, input clears + refocuses).
> Green: `rspec` (no regressions), `tsc`, `vite build`.

## Goal

Make note-taking the fastest thing on the video page by moving it into an **always-visible fixed
footer bar**, and clean up the page around it:

1. **Quick-capture footer** pinned to the bottom of the viewport (clears the sidebar on `lg`).
   - Start time is **blank until the title is focused**; first focus pins it to the playhead and it
     then stays put. It does **not** live-tick with playback (that was distracting).
   - Time controls live **above** the input, split into two clusters: **start on the left** (with
     its ±10/±5s nudges + "⟲ now") and **end on the right** (a "+ end time" button that fills the
     current playhead, then an editable end input with its **own** "⟲ now" + an ✕ to remove).
   - Both start and end are **editable text inputs** (`m:ss`).
   - **Add note** button lives **inside** the input and only appears once you type.
   - **Details** disclosure (⌘/Ctrl+↑) expands taxonomy + body **upward** out of the bar.
   - **⌘/Ctrl+⏎** (and Shift+⏎) submits. Adding clears the bar and re-focuses for rapid capture.
2. **Timeline panel**: drop the old "+ Note at current time" button + its inline form (the footer
   replaces it); promote **+ Segment** to a real full-width primary button beside **Organize**.
3. **Below-video details**: move **Description to the bottom**, below Tags.
4. **Remove the Chapters strip** (it duplicated the segment list in the right panel).

## Non-goals / decisions

- **Version A** is the build target (expandable Details). Switching to B (everything inline on
  focus) is a localized change to the footer component if we change our minds.
- No backend changes — `App::NotesController#create` already permits `note_type, start_seconds,
  end_seconds, title, body` + taxonomy. Quick notes are `note_type: "timestamp"`, point or range.
- A point note with no title is **not** allowed from the bar (Add only appears with text) — matches
  the mockup; title-less time markers stay a future idea.

## Plan

- **New** `app/frontend/components/QuickCapture.tsx` — the footer. Props: `videoId`,
  `getCurrentTime`, `opts` (taxonomy). Owns its own `POST /notes` (preserveScroll/State reload).
  Reuses `TaxFields`/`emptyDraft`/`taxonomyPayload` from `components/timeline/forms.tsx`.
- **Edit** `TimelinePanel.tsx` — remove note-creation UI (`noteFormAt`, `addNote`,
  `NoteCreateForm`); make the head a single row: `+ Segment` (primary, `flex-1`) + Organize toggle.
- **Edit** `pages/videos/Show.tsx` — render `<QuickCapture>`; remove `<ChapterStrip>`; add bottom
  spacer so content clears the fixed bar.
- **Edit** `VideoDetails.tsx` — render the Description row **after** the Tags row.
- `ChapterStrip.tsx` becomes unused; leave the file (used nowhere) or delete — delete to keep tsc
  honest about dead imports.

## Exit criteria

- [x] Footer matches `260618-video-page-full.html` (A): blank-until-focus start, left start cluster
      / right end cluster, +end with its own "⟲ now" + ✕, inline Add appearing on input, taller box.
- [x] ⌘/Ctrl+⏎ adds a note; ⌘/Ctrl+↑ toggles Details; adding clears + refocuses.
- [x] Range note (start+end) supported (`end_seconds` sent when +end is on); point note otherwise.
- [x] Timeline panel has no "+ Note" button; "+ Segment" is a full-width primary button.
- [x] Description renders below Tags; the Chapters strip is gone.
- [x] **Visual: the live page (`/videos/:id`) matches the mockup** — verified in a headless browser
      across collapsed / typed / end-active states, plus an end-to-end add.
- [x] Green gate: `bundle exec rspec` (no regressions), `npm run check` (tsc), `bin/vite build`.
      (No Ruby changed, so rubocop is unaffected.)
