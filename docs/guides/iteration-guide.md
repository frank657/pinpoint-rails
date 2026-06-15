# Iteration Guide

How we build Pinpoint after the initial phases: in small, documented, **test-driven**
iterations. Phases (`../roadmap/phases/`) built the system bottom-up; **iterations** are the
ongoing unit of work on top of it — a feature, a redesign, a refactor. Each one is a short
document plus a TDD loop with explicit **exit criteria**.

The two rules:

1. **Every iteration has a document with exit criteria.** No exit criteria → not started.
2. **Exit criteria always include a green suite, and the work is TDD: tests first.**

Iteration docs live in `../roadmap/iterations/NNNN-short-slug.md`, numbered sequentially. Copy
`../roadmap/iterations/_TEMPLATE.md` to start. See `0001` and `0004` for worked examples.

## The document (sections, in order)

The template is the source of truth; this explains the intent of each section.

1. **Status header** — a blockquote with `Status` (📋 planned · 🚧 in progress · ✅ done),
   `Owner`, `Started`, `Shipped`, and links to the governing **ADR** / **phase** / **mockup**.
2. **Goal & context** — what and *why*, in a few sentences. State "the bar": how you'll know
   it's good, not just done.
3. **Mockup** *(required for any UI-visible change; omit otherwise)* — link the reference in
   `docs/mockups/`. **When present, "matches the mockup" is an exit criterion.** If you're
   asked for a mockup-first iteration, the mockup is built and approved before the test plan.
4. **Locked decisions** — the choices this iteration commits to. Must not contradict an
   accepted ADR (`docs/decisions/`); if it would, write a new ADR first.
5. **Test plan (write these FIRST)** — the concrete tests that *define done*, grouped by layer
   (model / request / policy / service / job / system / frontend). This is the heart of the
   iteration: it's the executable form of the exit criteria. Use `testing-guide.md` to pick
   layers. Each line should be specific enough to turn into a failing test directly.
6. **Build steps** — the implementation outline that will make the test plan pass.
7. **Exit criteria** — a checkbox list. Behavioral checkboxes (one per promised capability) +
   the mockup checkbox if applicable + the **standard gate** (always):
   - [ ] `bundle exec rspec` green (incl. the new specs from the test plan)
   - [ ] `npm run check` (tsc) clean
   - [ ] `bin/vite build` succeeds
   - [ ] `bundle exec rubocop` clean
8. **What shipped** *(filled at the end)* — the actual files/changes, as a record.
9. **Out of scope** — what you deliberately didn't do, and where it goes instead.

## The loop (TDD)

```
   ┌─ 1. WRITE THE DOC ──────────────────────────────────────────────┐
   │   goal · (mockup) · locked decisions · TEST PLAN · exit criteria │
   └─────────────────────────────────────────────────────────────────┘
                              │
   ┌─ 2. RED ─────────────────▼──────────────────────────────────────┐
   │   Write the tests from the test plan. Run them. Watch them FAIL  │
   │   for the right reason (asserting the behavior, not a typo).      │
   └──────────────────────────────────────────────────────────────────┘
                              │
   ┌─ 3. GREEN ───────────────▼──────────────────────────────────────┐
   │   Implement the build steps until the new tests pass. Smallest    │
   │   change that does it.                                            │
   └──────────────────────────────────────────────────────────────────┘
                              │
   ┌─ 4. REFACTOR ────────────▼──────────────────────────────────────┐
   │   Clean up with the tests as a safety net. Suite stays green.     │
   └──────────────────────────────────────────────────────────────────┘
                              │
   ┌─ 5. VERIFY EXIT CRITERIA ▼──────────────────────────────────────┐
   │   Run the full gate (rspec · tsc · vite build · rubocop). If a    │
   │   mockup exists, compare against it (a system spec or screenshot).│
   │   Tick every box. A box you can't tick honestly isn't done.       │
   └──────────────────────────────────────────────────────────────────┘
                              │
   ┌─ 6. CLOSE ───────────────▼──────────────────────────────────────┐
   │   Fill "What shipped", set Status ✅, record the result line      │
   │   (e.g. "rspec 142/0, tsc clean, vite ok, rubocop clean").        │
   └──────────────────────────────────────────────────────────────────┘
```

When new requirements surface mid-iteration, either fold them into the test plan + exit
criteria (small) or push them to "Out of scope" and a follow-up iteration (large). The doc and
the code stay in sync.

### On mockup-first iterations

When the iteration starts from a mockup: build/agree the mockup in `docs/mockups/` **before**
step 1's test plan, link it in §3, and add an exit-criteria checkbox "UI matches
`docs/mockups/<file>`". Verify it at step 5 with a system-spec screenshot or a side-by-side.
The mockup is a contract, not a suggestion.

## Setting up system specs (one-time, first system spec)

Capybara + `selenium-webdriver` are already in the Gemfile. The first system iteration adds:

- `spec/system/` and a driver config in `spec/support/capybara.rb` registering headless Chrome
  (`selenium_chrome_headless`), with `driven_by` in a `type: :system` hook.
- Host handling so Capybara hits `app.lvh.me` (Inertia + the subdomain constraint).

After that, system specs are just `type: :system` files. See `testing-guide.md` for which
journeys deserve one.
