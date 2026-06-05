# ADR 0004 — Three-axis model: content vs. taxonomy vs. per-user state

- **Status:** Accepted
- **Date:** 2026-06-04
- **Decision owner:** Frank Zhu

---

## Context

Pinpoint mixes three things that *feel* related but behave completely differently under
sharing, forking, and multi-user workspaces:

1. The **stuff itself** — videos, notes, courses.
2. The **labels** on that stuff — categories, tags, and (for BJJ) positions/techniques.
3. **What a person did** with that stuff — progress, review schedule, training log.

Every mature app studied (Notion, Anki, Readwise, Coursera) keeps these distinct. Anki's
foundational split is *Note ≠ Card*: one piece of content (a note) has separate,
per-user, independently-scheduled review state (cards). Conflating them is the single most
common data-model mistake in this space, and it is nearly impossible to untangle after
sharing/forking ship.

## Decision

Model three **separate axes** with separate tables. A column's axis determines which table
it lives on.

**Axis 1 — Content** (shared & forkable; ADR 0005):
Video, Vod, Segment, Chapter, Course, CourseItem, Curriculum, CurriculumItem, Note, Folder.

**Axis 2 — Taxonomy** (labels; workspace-scoped, curated):
Category (user-defined, for notes), Tag (free-form), and the BJJ taxonomy Position +
Technique (Technique is a typed edge: `from_position`, `to_position`, `kind` ∈
escape/sweep/pass/submission/transition). Free-form Tags and the curated Position/Technique
graph are **kept separate** — a free Tag is a string; a Position is a first-class queryable
row.

**Axis 3 — Per-user state** (never shared, always private; keyed by user + workspace):
Progress (per content item: completed_at, resume_seconds), ReviewCard (FSRS scheduling
state for a Note), TrainingSession (BJJ drilling/sparring log).

### Hard rules

- **Content tables carry no per-user state.** No `completed`, `due_at`, `last_reviewed`,
  `streak`, etc. on Video/Note/Course. Those live on Axis 3, keyed by `(user_id,
  workspace_id, <content>_id)`.
- **A Note is content; its ReviewCard(s) are per-user state.** One Note may spawn ≥1
  ReviewCards (Anki model) — never put `due_at`/FSRS fields on Note.
- **Timestamps are numeric seconds** (float), never formatted strings. Notes/Segments
  support an optional `[start_seconds, end_seconds]` **range** as well as a single point
  (range = `end_seconds` null).
- **Stable UUIDs** on deep-linkable units (Note, Segment, Chapter) so links survive renames
  and reordering.

## Consequences

- ✅ Forking is clean: deep-copy Axis 1, re-point Axis 2 into the forker's workspace, copy
  **nothing** from Axis 3. Your progress/review/log never leak to someone who forks your
  course, and theirs never touches yours.
- ✅ A single Note can be reviewed on multiple independent schedules (multiple cards), and
  shared Notes can be reviewed by each user privately.
- ✅ Per-user state is naturally `(user, workspace)`-scoped, matching ADR 0002.
- ⚠️ More tables and more joins than a "just put a column on it" design. This is the
  deliberate cost; it is far cheaper than retrofitting the split after sharing ships.
- ⚠️ Discipline required: every new column needs an explicit "which axis?" answer. CLAUDE.md
  restates this so it isn't forgotten.

## Alternatives considered

- **Flags on content rows** (`note.completed`, `note.due_at`). Rejected: breaks the moment
  content is shared/forked or a workspace has >1 member — state is per-user, content is not.
- **One global tag namespace covering both free tags and BJJ taxonomy.** Rejected: merging
  makes the curated taxonomy un-queryable (can't ask "all notes whose position is
  closed-guard" if it's just a string among arbitrary tags). Keep the axes separate.
- **Single polymorphic "block" table (Notion-style).** Considered; rejected as over-general
  for our needs — we don't need arbitrary block polymorphism, and concrete tables give us
  real constraints and clearer queries. We borrow Notion's *ideas* (deep-copy fork, single
  parent for permissions) without its universal block table.

## Sources

- Anki note-vs-card model: <https://docs.ankiweb.net/getting-started.html>
- FSRS scheduling: <https://github.com/open-spaced-repetition/fsrs4anki>
- Notion data model: <https://www.notion.com/blog/data-model-behind-notion>
