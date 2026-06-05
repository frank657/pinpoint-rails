# Phase 9 — Training / drilling log

**Goal:** a BJJ-style **training journal** that bridges *watching* and *doing* — log
sessions (drilling, rolling, classes, competition) and link them back to the techniques and
notes you studied. The unique connective tissue no pure video-annotator has.

**Depends on:** Phase 3 · **Locked by:** ADR 0004 (per-user state is Axis 3)

## Scope

### TrainingSession (Axis 3 — per-user)
- `TrainingSession`: `user_id`, `workspace_id`, `date`, `gi:boolean`,
  `kind:enum { drill, roll, positional, class, competition }`, `duration_minutes`,
  `location`/`gym`, `partners` (free text or refs), `body` (rich notes/reflection),
  `mood`/`intensity` (optional).
- Links: a session references **Techniques worked** and/or **Notes** studied
  (`training_session_techniques`, `training_session_notes` joins) — connecting the log to
  the instructional content.
- Outcomes tracking (optional): submissions/sweeps hit & conceded, "what to work on".

### Generic vs BJJ
- The core `TrainingSession` is generic ("practice session for any skill"); BJJ-specific
  fields (gi/no-gi, submissions) live in a clearly separable module/columns so non-BJJ
  users aren't burdened. (Mirrors the app's "BJJ-first, general-purpose" stance.)

### UX
- Quick session entry; calendar/timeline of sessions; charts (mat time, frequency,
  streaks) reusing Phase 7 streak logic.
- From a Note or Technique: "log that I drilled this" → pre-filled session link.
- "Techniques to work on" surfaced from sessions.

## Key tasks
1. `TrainingSession` model + join tables to Techniques/Notes; factories/specs.
2. Session entry UI + calendar/timeline + basic charts.
3. Cross-links: log-from-note / log-from-technique; "to work on" list.
4. Separate BJJ-specific fields behind a module/setting.

## Out of scope
- Technique taxonomy itself (Phase 10 — this phase links to it if present; degrades to free
  text if not).
- Social/shared training logs (per-user by design).

## Exit criteria
- Log a session (date, gi/no-gi, kind, duration, partners, reflection); it appears on the
  calendar and in mat-time charts.
- Link a session to a Note and (if Phase 10 done) a Technique.
- "Log this" from a note pre-fills a session referencing it.
- Training data is strictly per-user+workspace and never copied on fork (spec).
