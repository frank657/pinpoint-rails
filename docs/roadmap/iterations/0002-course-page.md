# Iteration 0002 — Friendly Course page

> **Status:** ✅ done · **Owner:** Frank · **Started:** 2026-06-05 · **Shipped:** 2026-06-05
> Builds on iteration 0001 (Tatami theme + AppShell). Reference: `docs/mockups/direction-a-course.html`.

## Problem

`courses/Show` reads as a raw **editor form**, not a course: it leads with "Add a video" /
"New chapter" inputs and per-row admin controls (▲▼, Remove, chapter dropdown), the single
lesson is bare text in a full-bleed band, and there's a huge empty void below. No thumbnails,
durations, note counts, watched state, or context. ~90% of visits are "watch the next
lesson," but the page is optimized for the ~10% "restructure" case.

## Locked decisions

1. **View-first, edit-on-toggle.** Default is a clean, clickable "study" view. An **Edit**
   toggle reveals add-video / new-chapter / reorder / remove. No always-on form inputs.
2. **Lessons are cards, grouped under chapters.** Each card: thumbnail, number, title,
   duration, note count, and a state chip (Watched / Resume / Not started).
3. **Course header** with a real progress bar and a **Resume** CTA (first not-completed
   lesson). Constrained content width so one lesson doesn't look lost.
4. **Backend adds per-item fields only** — no model/route/ADR changes. `course_detail`
   gains `durationSeconds`, `noteCount`, `resumeSeconds`, `completed` per item.

## Build steps

1. `App::CoursesController#course_detail` — per-item `durationSeconds`, `noteCount`
   (`Note.group(:video_id)`), `resumeSeconds` + `completed` (from a `Progress` map).
2. `pages/courses/Show.tsx` — header (breadcrumb, title, Share + Edit, progress bar, meta
   line, Resume CTA); view mode (chapter-grouped lesson cards); edit mode (add/reorder/remove
   + chapter assignment). Reuse existing endpoints verbatim.
3. Verify: `rspec` (existing `courses_spec` stays green — props-shape only), `tsc`,
   `vite build`, `rubocop`.

## Exit criteria

- [ ] Default view is clean & clickable; no form inputs visible until **Edit**.
- [ ] Lessons show thumbnail, duration, note count, and Watched/Resume/Not-started state,
      grouped under their chapters.
- [ ] Header has a visible progress bar + working **Resume** CTA.
- [ ] Edit mode still adds videos, creates chapters, assigns chapters, reorders, removes.
- [ ] `rspec`, `tsc`, `vite build`, `rubocop` all green.

## Out of scope

- Drag-and-drop reorder (keep ▲▼ in edit mode for now).
- Real video thumbnails (gradient placeholder until cover images land).
- Curriculum page reskin (separate follow-up).
