# Phase 8 — Spaced repetition (FSRS)

**Goal:** turn notes into a **spaced-repetition review** system — the core learning
differentiator. A Note can spawn one or more **review cards** scheduled with **FSRS**, with
a gentle daily-review default and scoped/themed review queues.

**Depends on:** Phase 3 (notes), Phase 7 (per-user state pattern) ·
**Locked by:** ADR 0004 (Note ≠ Card; scheduling is Axis 3)

## Scope

### ReviewCard (Axis 3 — per-user, NEVER on Note)
- `ReviewCard`: `user_id`, `note_id`, `card_template` (e.g. `basic`, `cloze:N`),
  `due_at`, `state:enum { new, learning, review, relearning }`, `stability:float`,
  `difficulty:float`, `reps:int`, `lapses:int`, `last_reviewed_at`.
- **One Note → ≥1 cards** (Anki model). Cloze-style notes generate one card per deletion.
- **No FSRS/scheduling field ever on Note** (ADR 0004) — so a shared Note is reviewed
  independently by each user.

### Scheduling (FSRS)
- Use an open-source **FSRS** implementation (Ruby port) for due-date scheduling from
  `Again/Hard/Good/Easy` grades; persist DSR state per card.
- Nightly job recomputes/surfaces due cards; per-user.

### Review UX
- **Daily Review** (Readwise-style gentle default): a small queue of due cards surfaced
  daily; low friction, no config needed.
- **Themed / scoped queues** (Readwise frequency tuning): review only cards whose note
  matches a filter — by category, tag, course, video, or (later) position/technique.
- Create-card affordances: "add to review" on a note; auto-suggest cloze from selected text;
  optionally generate cards from notes (AI draft lands in Phase 11).

### BJJ fit
- Cloze works well for details ("from closed guard, the first grip is {{c1::sleeve and
  collar}}"). Scoped queues map to "drill closed-guard cards this week".

## Key tasks
1. `ReviewCard` model + FSRS port integration; grade → schedule update; specs against known
   FSRS vectors.
2. Card generation from notes (basic + cloze parsing).
3. Daily Review queue + review session UI (grade buttons, seek-to-note context).
4. Themed/scoped queues (filter by taxonomy/course/tag).
5. Nightly due-recompute job (Sidekiq cron).

## Out of scope
- AI-drafted cards (Phase 11) — manual + cloze here.
- Cross-user shared decks (cards are per-user by design).

## Exit criteria
- Turn a note into a card; grade it; `due_at`/stability update per FSRS (spec).
- A cloze note with two deletions yields two cards.
- Daily Review shows only due cards; a themed queue filters to one category/tag/course.
- Reviewing a **shared** note creates cards on the reviewer's account only — the owner's
  schedule is untouched (spec — Axis-3 separation).
