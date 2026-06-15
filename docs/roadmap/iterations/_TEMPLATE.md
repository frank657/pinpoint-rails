# Iteration NNNN — <short title>

> **Status:** 📋 planned · **Owner:** <name> · **Started:** YYYY-MM-DD · **Shipped:** —
> Links: ADR <nnnn> (if any) · Phase <n> (if any) · Mockup `docs/mockups/<file>` (if any)
>
> See `docs/guides/iteration-guide.md` for how this document is structured and the TDD loop.

## Goal & context

<What this iteration delivers and why. State "the bar" — how we'll know it's good, not just
done.>

## Mockup

<Required only for UI-visible changes; delete this section otherwise.>
Reference: `docs/mockups/<file>`. **Exit:** the built UI matches this mockup.

## Locked decisions

<The choices this iteration commits to. Must not contradict an accepted ADR — if it would,
write a superseding ADR first.>

1. …

## Test plan (write these FIRST)

<The concrete tests that define "done", grouped by layer. Each line should be specific enough
to become a failing test directly. Use docs/guides/testing-guide.md to choose layers.>

- **Model** (`spec/models/…`): …
- **Request** (`spec/requests/…`): … (assert component + props; auth gate; tenant scoping)
- **Policy** (`spec/policies/…`): … (rule × {owner, member, outsider, admin})
- **Service** (`spec/services/…`): …
- **System** (`spec/system/…`): … (only for a critical browser journey)
- **Frontend** (`*.test.tsx`): … (only for non-trivial isolated client logic)

## Build steps

1. …

## Exit criteria

- [ ] <behavioral capability 1>
- [ ] <behavioral capability 2>
- [ ] UI matches `docs/mockups/<file>` *(if a mockup applies)*
- [ ] `bundle exec rspec` green (incl. the new specs above)
- [ ] `npm run check` (tsc) clean
- [ ] `bin/vite build` succeeds
- [ ] `bundle exec rubocop` clean

## What shipped

<Filled at close: the actual files/changes, plus the result line — e.g. "rspec 142/0, tsc
clean, vite ok, rubocop clean".>

## Out of scope

<What was deliberately deferred, and where it goes next.>
