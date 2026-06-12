# Iteration 0003 — Course → Notebook (drop Curriculum + Folder)

> **Status:** ✅ done · **Owner:** Frank · **Started:** 2026-06-05 · **Shipped:** 2026-06-05
> Locked by **ADR 0010** (supersedes 0003). Renames the content container to **Notebook**
> and removes the Curriculum + Folder concepts.
>
> **Result:** rspec 117/0, tsc clean, vite build ok, rubocop clean (185 files). Zero
> Course/Curriculum/Folder symbols remain in app/config/spec; migration preserved data
> (the "Judo for BJJ" course is now a Notebook).

## Decision (locked)

`Course → Notebook`, `Course::Chapter → Notebook::Chapter`, `Course::Item → Notebook::Item`.
Remove `Curriculum`, `Curriculum::Item`, `Folder`. Nav becomes **Notebooks** (containers) +
**Notes** (annotations). The Notes view keeps the Tatami design we built for `/notebook`
(minus the folder rail); `/notebook` (the old notes-browser) is retired.

## Change map

**Migration** (one file, order matters — drop FK-dependents first):
1. `remove_column :notes, :folder_id` · `drop_table :curriculum_items` · `drop_table :curriculums` · `drop_table :folders`
2. `rename_table :courses → :notebooks`, `:course_chapters → :notebook_chapters`, `:course_items → :notebook_items`
3. `rename_column` course_id→notebook_id (chapters, items), course_chapter_id→notebook_chapter_id (items)
4. Repoint polymorphic strings `"Course"→"Notebook"` in `shares.shareable_type`,
   `forks.source_type`/`target_type`, `progresses.trackable_type`; delete
   `"Curriculum"`/`"Folder"` rows in those tables.

**Models:** `course.rb`→`notebook.rb`, `course/{chapter,item}.rb`→`notebook/{chapter,item}.rb`
(table names + FK columns + uniqueness scope); delete `curriculum*.rb`, `folder.rb`;
`Video.course_items`→`notebook_items`; `Note` drop `belongs_to :folder`; `Shareable` comment.

**Controllers/routes/policies:** `App::CoursesController`→`NotebooksController`,
`Courses::{Items,Chapters}`→`Notebooks::{Items,Chapters}`; routes `/courses`→`/notebooks`;
`CoursePolicy`→`NotebookPolicy`; delete `curriculums*`, `folders`, `notebook` (notes-browser)
controllers + `Curriculum`/`Folder` policies; `admin/dashboard` counts; `forks`/`shares`
shareable whitelist; `content_json` drop `folderId`.

**Service:** `ForkService` `copy_course`→`copy_notebook`, drop `copy_curriculum`/`copy_folder`.

**Frontend:** `pages/courses/*`→`pages/notebooks/*`; delete `pages/{curriculums,folders,notebook}/*`;
`notes/Index.tsx` ← the Tatami design (drop folders); `AppShell` nav; `Dashboard`/`Landing`
links; `ShareButton` type `"Course"`→`"Notebook"`.

**Specs/factories:** `courses.rb`→`notebooks.rb` factory; `courses_spec`→`notebooks_spec`;
delete `curriculums_and_folders_spec`, `notebook_spec`; update `sharing_spec`, `progress_spec`,
`fork_service_spec`.

## Exit criteria

- [ ] No `Course`/`Curriculum`/`Folder` symbols remain in `app/`, `config/`, `spec/` (only
      historical migrations).
- [ ] `db:migrate` runs clean on dev + test; existing "Judo for BJJ" course is now a Notebook
      with its notes intact.
- [ ] Nav shows **Notebooks** + **Notes**; `/notebooks`, `/notebooks/:slug` work; sharing a
      Notebook + forking it still works.
- [ ] `rspec`, `tsc`, `vite build`, `rubocop` all green.

## Out of scope

- A grouping layer above Notebook (deferred; new ADR if revived).
- Reskinning the Notes view beyond porting the Tatami design.
