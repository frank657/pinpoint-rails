# ADR 0004 — Three-axis model: content vs. taxonomy vs. per-user state

- **Status:** Accepted
- **Date:** 2026-06-04
- **Decision owner:** Frank Zhu

---

## Context

Pinpoint mixes three things that *feel* related but behave completely differently under
sharing, forking, and multi-user workspaces:

1. The **stuff itself** — videos, notes.
2. The **labels** on that stuff — categories, tags, and (for BJJ) positions/techniques.
3. **What a person did** with that stuff — their progress.

Every mature app studied (Notion, Anki, Readwise) keeps these distinct. Conflating per-user
state with content is the single most common data-model mistake in this space, and it is
nearly impossible to untangle after sharing/forking ship.

## Decision

Model three **separate axes** with separate tables. A column's axis determines which table
it lives on.

**Axis 1 — Content** (shared & forkable; ADR 0005):
Video, Vod, Video::Segment, Note.

**Axis 2 — Taxonomy** (labels; workspace-scoped, curated):
Category (user-defined, for notes), Tag (free-form), and the BJJ taxonomy Position +
Technique (Technique is a typed edge: `from_position`, `to_position`, `kind` ∈
escape/sweep/pass/submission/transition/takedown). Free-form Tags and the curated
Position/Technique graph are **kept separate** — a free Tag is a string; a Position is a
first-class queryable row.

**Axis 3 — Per-user state** (never shared, always private; keyed by user + workspace):
Progress (per content item: `completed_at`, `resume_seconds`, `last_viewed_at`).

### Hard rules

- **Content tables carry no per-user state.** No `completed`, `resume_seconds`,
  `last_viewed`, `streak`, etc. on Video/Note. Those live on Axis 3, keyed by `(user_id,
  workspace_id, <content>_id)`.
- **Timestamps are numeric seconds** (float), never formatted strings. Notes/Segments
  support an optional `[start_seconds, end_seconds]` **range** as well as a single point
  (range = `end_seconds` null).
- **Stable UUIDs** on deep-linkable units (Note) so links survive renames and reordering.
- Per-user state that is genuinely cross-cutting stays a single polymorphic table rather than
  one-per-content-type — see `Progress`, whose `trackable` is polymorphic.

## Consequences

- ✅ Forking is clean: deep-copy Axis 1, copy **nothing** from Axis 3. Your progress never
  leaks to someone who forks your video, and theirs never touches yours.
- ✅ Per-user state is naturally `(user, workspace)`-scoped, matching ADR 0002.
- ⚠️ More tables and more joins than a "just put a column on it" design. This is the
  deliberate cost; it is far cheaper than retrofitting the split after sharing ships.
- ⚠️ Discipline required: every new column needs an explicit "which axis?" answer. CLAUDE.md
  and `docs/guides/models-guide.md` restate this so it isn't forgotten.

## Alternatives considered

- **Flags on content rows** (`note.completed`, `video.resume_seconds`). Rejected: breaks the
  moment content is shared/forked or a workspace has >1 member — state is per-user, content is
  not.
- **One global tag namespace covering both free tags and BJJ taxonomy.** Rejected: merging
  makes the curated taxonomy un-queryable (can't ask "all notes whose position is
  closed-guard" if it's just a string among arbitrary tags). Keep the axes separate.
- **Single polymorphic "block" table (Notion-style).** Considered; rejected as over-general
  for our needs — concrete tables give us real constraints and clearer queries. We borrow
  Notion's *ideas* (deep-copy fork, single parent for permissions) without its universal
  block table.

## Sources

- Anki note-vs-card model (separating content from per-user state): <https://docs.ankiweb.net/getting-started.html>
- Notion data model: <https://www.notion.com/blog/data-model-behind-notion>
