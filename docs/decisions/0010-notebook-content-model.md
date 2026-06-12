# 0010 — Notebook content model (supersedes 0003)

- **Status:** Accepted (2026-06-05)
- **Supersedes:** [0003 — Course/Curriculum content model](0003-course-curriculum-content-model.md)
- **Related:** 0004 (three-axis), 0005 (sharing/forking)

## Context

ADR 0003 defined a two-level content hierarchy: **Curriculum → Course → Chapter → Video**.
In practice this is over-structured for the product. Users think in one container — "the set
of videos I'm studying, with my notes on them" — not in a shelf-of-courses. The word that
fits that container, in a video **note-taking** app, is **Notebook**. The extra Curriculum
layer and the separate Notes **Folder** concept added IA weight without pulling their weight.

## Decision

The content container is a **Notebook** (was **Course**). A Notebook holds ordered
**Notebook::Chapter**s, each holding ordered **Notebook::Item**s that point at Videos. A
user's Notes (Axis 1) attach to the Videos inside a Notebook.

- **Rename:** `Course → Notebook`, `Course::Chapter → Notebook::Chapter`,
  `Course::Item → Notebook::Item` (tables `notebooks`, `notebook_chapters`, `notebook_items`;
  FK columns `notebook_id`, `notebook_chapter_id`). Namespaced per the project convention
  (nested models set explicit `self.table_name`).
- **Removed:** `Curriculum` + `Curriculum::Item` (the shelf-of-courses layer) and `Folder`
  (note organizer). A Notebook *is* the organizer; Notes are browsed in a flat **Notes** view
  and filtered by category/tag/notebook.
- **Unchanged:** the three-axis split (0004) and deep-copy fork/share (0005) — a Notebook is
  still Axis-1 content (shared & forkable); media shared by reference; per-user state never
  copied. Sharing/forking now targets `Notebook` instead of `Course`/`Curriculum`/`Folder`.

## Consequences

- Polymorphic references that stored `"Course"` (shares, forks, progress) are migrated to
  `"Notebook"`; `"Curriculum"`/`"Folder"` rows are dropped.
- The nav surfaces **Notebooks** (containers) and **Notes** (annotations) — no Courses /
  Curriculums / Folders.
- One less hierarchy level: grouping several Notebooks (a "track") is deferred; if revived it
  gets its own ADR rather than resurrecting Curriculum.

See `docs/roadmap/iterations/0003-notebook-rename.md` for the migration mechanics.
