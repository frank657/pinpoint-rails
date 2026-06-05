# ADR 0003 — Course + Curriculum naming and the video-grouping model

- **Status:** Accepted
- **Date:** 2026-06-04
- **Decision owner:** Frank Zhu

---

## Context

The user needs a way to *"organize videos in a self-defined curriculum / learning topic …
it can have multiple videos, where users arrange the order, and a video can belong to
multiple curriculums."* Mature platforms (Udemy, Coursera, Submeta) converged on a
hierarchy of **Course → Section → Lecture/Video**, with an optional supersequence above
(Coursera's "Specialization"). The user reviewed and chose the two-tier naming.

## Decision

### Naming (chosen)

- **Curriculum** — the top-level, ordered grouping of multiple **Courses** (≈ Coursera
  Specialization). For "the whole back-attack system spanning several instructionals."
- **Course** — one coherent, ordered set of videos. The unit users create and fork most.
- **Chapter** — an **optional** section *inside a Course* that groups videos (Course →
  Chapter → Video).
- **Segment** — a labeled **time-range inside a single Video** (the YouTube-"chapter"
  analog / clippable region). Distinct from Chapter to avoid overloading the word.
- **Folder** — note organization (see ADR 0004 / note model); orthogonal to the above.

> Naming nuance: the user said both "group videos into a chapter" and "group notes into a
> chapter." We resolve this as: **Chapter groups videos within a Course**; notes roll up to
> a chapter *through the video they annotate*, and notes are also directly organizable via
> **Folders** and **Categories**. If a need emerges to attach a note directly to a Chapter
> independent of a video, revisit here.

### Structure (relationships)

All grouping is **many-to-many via ordered join tables**, never parent foreign keys on the
child — because a Video belongs to many Courses and a Course to many Curriculums:

- `Course ⟷ Video` through **CourseItem** (`course_id`, `video_id`, `chapter_id` nullable,
  `position`). A Video can appear in many courses; ordering and chapter-membership live on
  the join, not the Video.
- `Chapter` belongs to a Course and groups its CourseItems (`position` within the course).
  **Optional** — a Course with no chapters just holds videos directly (no empty "Section 1"
  wrapper forced on users).
- `Curriculum ⟷ Course` through **CurriculumItem** (`curriculum_id`, `course_id`,
  `position`).
- `Segment` belongs to a Video (`start_seconds`, `end_seconds`, `title`, `position`).

All of these are `acts_as_tenant :workspace` (ADR 0002) and are **content** (shared/forkable,
ADR 0005).

## Consequences

- ✅ A video is reused across courses/curriculums with independent ordering — no duplication
  of the underlying media.
- ✅ Intermediate hierarchy (Chapter) is optional, matching casual→power-user needs.
- ✅ Naming matches users' mental models from Udemy/Coursera/Submeta; "Curriculum" signals
  serious, structured learning without LMS jargon ("path").
- ⚠️ Ordering is a `position` integer on join rows; reordering rewrites positions
  (acceptable at expected scale; consider fractional/rebalanced positions if drag-reorder
  gets heavy).
- ⚠️ Deleting a Video must not orphan join rows — clean up CourseItems/Segments. Removing a
  Video from a Course deletes the CourseItem, not the Video.
- ⚠️ "Chapter" (course section) vs "Segment" (in-video range) vs "Curriculum" must be used
  consistently in code, UI copy, and guides to avoid confusion.

## Alternatives considered

- **"Course" only (no Curriculum).** Rejected by the user in favor of the two-tier model;
  Curriculum is needed to group multi-instructional systems.
- **"Path" / "Learning Path".** Rejected: LMS-trendy but implies a single authored route;
  "Curriculum/Course" reads as more structured and is the term comparable products use.
- **"Playlist" as the primary term.** Rejected: signals throwaway/casual, undersells the
  structured-learning intent. May exist later as a casual sibling.
- **Strict tree (parent_id on Video).** Rejected: a video belongs to many courses — a tree
  can't express that. Join tables are required (common pitfall avoided).
