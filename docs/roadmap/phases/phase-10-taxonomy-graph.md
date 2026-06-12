# Phase 10 — Technique taxonomy graph

**Goal:** a first-class **Position / Technique** taxonomy so notes tag into a browsable BJJ
map — Positions as nodes, Techniques as **typed edges** between them. Turns scattered notes
into a navigable system ("show every note about closed guard across all my videos").

**Depends on:** Phase 3 · **Locked by:** ADR 0004 (taxonomy is Axis 2, separate from tags)

## Scope

### Position & Technique (Axis 2 — curated taxonomy)
- `Position` (acts_as_tenant): `name`, `category:enum { standing, guard, pin, back, leg,
  turtle }`, `dominance:enum { dominant, neutral, inferior }`, optional `parent_id` for
  sub-positions (closed/half/open guard …).
- `Technique` (acts_as_tenant): `name`, `from_position_id`, `to_position_id` (nullable),
  `kind:enum { escape, sweep, pass, submission, transition, takedown }`. A technique is a
  **labeled edge** from one position to another.
- `note_techniques` / `note_positions` joins — a Note tags into the graph.
- **Separate from free-form Tags** (ADR 0004): Tags are arbitrary strings; Positions/
  Techniques are queryable first-class rows with relationships.

### Seed & generality
- Ship a sensible **BJJ seed taxonomy** (the standard position map) the user can extend;
  users can also build their own from scratch (and non-BJJ users can ignore or repurpose
  it — keep it optional per workspace).

### UX
- Tag a note/segment with positions/techniques.
- A **position page** aggregates every note/segment/video referencing it across the
  workspace (Logseq-style transclusion) — "all closed-guard material".
- A graph/map view of positions linked by techniques; click an edge → its notes/videos.
- Filter review queues (Phase 8) by position/technique.

## Key tasks
1. `Position`, `Technique` models + joins to notes; BJJ seed data; factories/specs.
2. Tagging UI on notes/segments.
3. Position aggregation page (all material for a position).
4. Graph/map visualization (positions + technique edges).
5. Hook into Phase 8 (scoped reviews) and Phase 9 (session technique links).

## Out of scope
- Auto-tagging via AI (could come with Phase 11).
- A global/shared canonical taxonomy across workspaces (each workspace owns its taxonomy;
  cross-workspace canon is a future ADR).

## Exit criteria
- Define positions and techniques (edges between them); seed taxonomy loads.
- Tag notes with positions/techniques; a position page shows all related material across
  videos.
- The graph view renders positions connected by technique edges and is navigable.
- Tags and the Position/Technique taxonomy are clearly separate systems (spec/UX).
