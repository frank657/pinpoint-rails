# Phase 7 — Progress tracking & resume

**Goal:** track what a user has watched/completed and let them resume where they left off,
with progress rollups at video → chapter → course → curriculum level. First slice of the
**learning layer** and the basis for review/streaks.

**Depends on:** Phase 4 · **Locked by:** ADR 0004 (per-user state is Axis 3)

## Scope

### Progress (Axis 3 — per-user state, NEVER on content tables)
- `Progress`: `user_id`, `workspace_id`, polymorphic `trackable` (Video / Course /
  Curriculum), `completed_at` (nullable), `resume_seconds:float` (video resume point),
  `last_viewed_at`. Unique on `(user_id, workspace_id, trackable)`.
- **No progress/completion columns on Video/Course/etc.** (ADR 0004) — so forked/shared
  content stays clean and each user's progress is independent.

### Behavior
- Player periodically writes `resume_seconds`; reopening a video seeks there.
- Marking/auto-detecting a video complete; manual toggle.
- **Rollups:** course progress = completed videos / total; curriculum progress = across its
  courses (Coursera model). Computed, not stored on content.
- "Continue watching" / "resume" surface on the dashboard; next-item suggestion.
- Optional **streaks** (consecutive days with activity) — per user+workspace.

## Key tasks
1. `Progress` model (polymorphic, per user+workspace) + unique index; factories/specs.
2. Player resume write/read; complete toggle + auto-complete heuristic.
3. Rollup queries (course/curriculum %); dashboard "continue watching".
4. Streak computation (optional) + display.

## Out of scope
- Spaced-repetition review of notes (Phase 8 — separate ReviewCard).
- Cross-user/leaderboard analytics.

## Exit criteria
- Watch part of a video, leave, return → resumes at the right second.
- Course/curriculum show an accurate completion % from per-video progress.
- A user's progress on a **forked** course is independent of the source owner's (spec —
  proves Axis-3 separation).
- No completion/resume column exists on any content table (spec/grep guard).
