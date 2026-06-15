# Phase 7 — Progress tracking & resume

**Goal:** track what a user has watched/completed and let them resume where they left off.
This is the surviving per-user **learning layer**.

**Depends on:** Phase 3 · **Locked by:** ADR 0004 (per-user state is Axis 3)

## Scope

### Progress (Axis 3 — per-user state, NEVER on content tables)
- `Progress`: `user_id`, `workspace_id`, polymorphic `trackable` (Video today — the
  polymorphism leaves room for other trackables later), `completed_at` (nullable),
  `resume_seconds:float` (video resume point), `last_viewed_at`. Unique on
  `(user_id, workspace_id, trackable)`.
- **No progress/completion columns on Video/Note** (ADR 0004) — so forked/shared content
  stays clean and each user's progress is independent.

### Behavior
- Player periodically writes `resume_seconds`; reopening a video seeks there.
- Marking/auto-detecting a video complete; manual toggle.
- "Continue watching" / "resume" surface on the dashboard.

## Key tasks
1. `Progress` model (polymorphic, per user+workspace) + unique index; factories/specs.
2. Player resume write/read; complete toggle + auto-complete heuristic.
3. Dashboard "continue watching".

## Out of scope
- Cross-user/leaderboard analytics.

## Exit criteria
- Watch part of a video, leave, return → resumes at the right second.
- A user's progress on a **forked** video is independent of the source owner's (spec —
  proves Axis-3 separation).
- No completion/resume column exists on any content table (spec/grep guard).
