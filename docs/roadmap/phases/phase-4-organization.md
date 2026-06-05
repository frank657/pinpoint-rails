# Phase 4 — Organization: Courses, Curriculums, Folders

**Goal:** organize videos into ordered **Courses** (with optional **Chapters**) and group
courses into **Curriculums**; organize notes into **Folders**. A video can live in many
courses; a course in many curriculums — all via ordered join tables.

**Depends on:** Phase 3 · **Locked by:** ADR 0003 (course/curriculum model)

## Scope

### Courses & Chapters (Axis 1)
- `Course` (acts_as_tenant): `title`, `slug` (FriendlyId), `description`.
- `Chapter` (acts_as_tenant, UUID): `course_id`, `title`, `position`. **Optional** — a
  course can hold videos directly without chapters (no forced empty section, ADR 0003).
- `CourseItem` (acts_as_tenant): `course_id`, `video_id`, `chapter_id` (nullable),
  `position`. The ordered, many-to-many join (a Video belongs to many Courses).

### Curriculums (Axis 1)
- `Curriculum` (acts_as_tenant): `title`, `slug`, `description`.
- `CurriculumItem` (acts_as_tenant): `curriculum_id`, `course_id`, `position`.

### Folders for notes (Axis 1)
- `Folder` (acts_as_tenant): `name`, `parent_id` (nullable, nestable), `position`.
- Wire `Note.folder_id` (column reserved in Phase 3); a note lives in 0..1 folder.

### Ordering
- `position` integer on each join/section; drag-to-reorder in the UI rewrites positions.
  (Consider fractional positions if reordering large lists gets heavy — ADR 0003 note.)

### Frontend
- Course builder: add videos, group into chapters, drag-reorder videos and chapters.
- Curriculum builder: add courses, drag-reorder.
- Folder tree for notes with drag-move.
- A video/course/curriculum can be viewed as a structured outline (Curriculum → Course →
  Chapter → Video).

## Key tasks
1. Course, Chapter, CourseItem models + ordered associations; builder UI + reorder.
2. Curriculum, CurriculumItem models + builder UI + reorder.
3. Folder model (nestable) + attach notes; folder tree UI + drag-move.
4. Cleanup rules: removing a video from a course deletes the CourseItem (not the Video);
   deleting a video cleans its CourseItems/Segments (ADR 0003).
5. pg_search across courses/curriculums.

## Out of scope
- Sharing/forking these structures (Phase 5).
- Progress rollups across a course/curriculum (Phase 7).

## Exit criteria
- Build a Course from several videos, group some into a Chapter, reorder both — order
  persists.
- Add the same Video to two different Courses with independent positions (proves
  many-to-many; spec).
- Build a Curriculum from multiple Courses and reorder.
- Create nested Folders and move notes between them.
- Removing a video from a course leaves the Video intact; deleting a Video cleans its joins
  (spec).
