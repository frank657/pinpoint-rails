# Iteration 0004 — Testing strategy + iteration/TDD process

> **Status:** ✅ done · **Owner:** Frank · **Started:** 2026-06-15 · **Shipped:** 2026-06-15
> Links: no ADR (process, not architecture) · no mockup (docs only)
>
> See `docs/guides/iteration-guide.md` for how this document is structured.

## Goal & context

The auth work this week shipped real bugs (blank page, the Inertia error modal, a silent CSRF
422) that the existing suite never caught — because there were no tests for the Inertia/React
seam and no repeatable definition of "done". Establish a **testing strategy** and a **TDD
iteration process** so that, going forward, every feature ships with tests and every iteration
has explicit exit criteria.

The bar: a newcomer (or a fresh Claude session) can read two guides and run an iteration the
same way every time — tests first, green gate before done.

## Locked decisions

1. **Two guides + a template.** `docs/guides/testing-guide.md` (what/where/how to test),
   `docs/guides/iteration-guide.md` (the doc structure + TDD loop), and
   `docs/roadmap/iterations/_TEMPLATE.md` (copy-to-start).
2. **Request specs are the workhorse; system specs cover the Inertia/React seam.** Capybara +
   selenium-webdriver are already in the Gemfile — system specs need only a harness, added with
   the first one.
3. **Mockups are optional but, when present, become an exit criterion.** Supports future
   mockup-first iterations.
4. **The standard gate is fixed:** `bundle exec rspec`, `npm run check` (tsc), `bin/vite build`,
   `bundle exec rubocop` — part of every iteration's exit criteria.
5. **CLAUDE.md points at the process** so it's followed by default.

## Test plan (write these FIRST)

This iteration ships documentation, not code, so "tests" are the verifiable properties of the
docs (checked in Build/Verify rather than RSpec):

- All four files exist and are non-empty.
- Every intra-repo path referenced by the guides/CLAUDE.md resolves to a real file.
- CLAUDE.md references both guides and the iterations dir.
- The existing RSpec suite is unaffected (still green — no code changed).

## Build steps

1. `docs/guides/testing-guide.md` — the layer table, the pyramid for this stack, the
   conventions (host!/sign_in/tenancy/Inertia helpers/stubbing), and the current gaps.
2. `docs/guides/iteration-guide.md` — the document sections + the TDD loop + system-spec setup
   note + mockup-first note.
3. `docs/roadmap/iterations/_TEMPLATE.md` — the copy-paste template.
4. `CLAUDE.md` — reference the guides + iterations dir; add the Testing + Development-workflow
   rules.

## Exit criteria

- [x] `testing-guide.md`, `iteration-guide.md`, `_TEMPLATE.md` exist and answer "what tests do I
      add?" with a per-feature layer table.
- [x] `iteration-guide.md` defines the doc structure, the TDD loop, and where the mockup fits.
- [x] CLAUDE.md references both guides + the iterations dir and codifies the TDD/exit-criteria rule.
- [x] All intra-repo links in the new docs resolve (verified by script).
- [x] `bundle exec rspec` still green (no code changed — sanity check).

## What shipped

- `docs/guides/testing-guide.md` — per-feature test-layer table, test pyramid for the
  Rails+Inertia stack, conventions, Inertia request-spec assertion pattern, current gaps.
- `docs/guides/iteration-guide.md` — iteration doc sections, the red→green→refactor→verify loop,
  mockup-first guidance, one-time system-spec harness note.
- `docs/roadmap/iterations/_TEMPLATE.md` — the iteration template.
- `CLAUDE.md` — Project Documents now lists the guides + iterations; Key Rules gained Testing +
  Development-workflow entries.

## Out of scope (→ next iteration, 0005)

- **Standing up the system-spec harness** and writing `spec/system/auth_spec.rb`.
- The **auth regression request specs** (Inertia-XHR redirect, `errors.base` on bad password,
  the CSRF rescue) called out in `testing-guide.md` § "What to add next".
