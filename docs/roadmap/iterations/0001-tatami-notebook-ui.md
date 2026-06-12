# Iteration 0001 — Tatami UI + Notebook

> **Status:** ✅ done · **Owner:** Frank · **Started:** 2026-06-05 · **Shipped:** 2026-06-05
> Iterations are post-Phase design/product passes layered on the finished phase build
> (`../DEVELOPMENT_PLAN.md`). They do not change locked ADRs; they apply look-and-feel and
> light IA changes. The HTML reference lives in `docs/mockups/` (Direction A + the four
> A-flow screens).

## Goal

Apply **Direction A — "Tatami"** (the warm, cinematic, player-first light theme) to the real
Inertia/React app, and introduce **"Notebook"** as the name for the notes surface
(consolidating the old separate **Notes** + **Folders** nav entries into one).

The bar: opening the app should feel like the `docs/mockups/direction-a-*.html` screens —
warm cream paper, ember accent, Fraunces display type, a left-sidebar app shell, and a
Notebook that reads like a study journal.

## Locked decisions (this iteration)

1. **Theme = Tatami, light.** Warm cream surfaces, ember primary, gold + teal supporting.
   Display font **Fraunces**, body **Hanken Grotesk**. (See tokens below.)
2. **Re-tone, don't rewrite.** The whole app is retoned by overriding Tailwind v4 theme
   colors (`neutral` → warm stone, `amber` → ember) in `@theme`, so every existing page
   inherits the palette for free. Only the **AppShell**, **Dashboard**, and **Notebook** get
   bespoke Tatami layouts this iteration.
3. **"Notebook" is the notes home.** Nav shows a single **Notebook** entry (icon ▤) that
   replaces both **Notes** and **Folders**. The Notebook page combines a folder rail
   (organizer) with the notes list (content). Old routes `/notes`, `/notes/new`, `/folders`
   stay for CRUD and back-compat; `/notebook` is the new primary surface.
4. **App shell = top bar + left sidebar** (YouTube/Linear-style), replacing the current
   single top-nav bar. Workspace switcher + create logic is preserved verbatim.
5. **No ADR changes, no model/tenancy changes.** Notebook is a read/compose view over
   existing `Note` + `Folder`; no new tables.

## Design tokens (locked)

Implemented in `app/frontend/entrypoints/application.css` via `@theme`.

| Token | Value | Use |
|------|-------|-----|
| bg / paper | `#f4eee4` | page background (remaps `neutral-100`) |
| surface | `#fffdf8` / `white` | cards/panels |
| raise | `#f0e6d6` | hover/active fills (`neutral-200/300`) |
| ink | `#2c2722` | primary text (`neutral-900`) |
| muted | `#6e645a` | secondary text (`neutral-500/600`) |
| faint | `#9b8f7f` | tertiary text (`neutral-400`) |
| line | `rgba(44,32,20,.10)` | hairline borders (`neutral-200`) |
| **ember** | `#e2571f` | primary accent (remaps `amber-400`); `amber-600` → `#c2410c` text |
| ember-2 | `#f0703a` | gradient top / hover |
| gold | `#bf8a2c` | range notes, timestamps |
| teal | `#3a9384` | point notes, "done" state |
| font-display | `"Fraunces"` | headings, wordmark, timestamps |
| font-sans | `"Hanken Grotesk"` | body |

Note-type colors: **point = teal**, **range = gold**, **cloze = ember** (consistent with the
mockups and the existing `note_type` enum).

## Build steps

1. **Theme foundation** — `application.css`: `@import` Google Fonts (Fraunces, Hanken
   Grotesk); `@theme` overrides for the neutral + amber ramps, `--font-sans`,
   `--font-display`; `@layer base` body bg/text + heading font. *(retones whole app)*
2. **AppShell v2** — rewrite `components/AppShell.tsx`: sticky top bar (wordmark → Home,
   search → Library, streak/due chips, avatar) + left sidebar (Workspace: Home, Library,
   Courses, Curriculums, Search · Learning: Review, **Notebook**, Training, Positions) with
   active-route highlighting. Keep `AppSharedProps`/`Workspace` exports + workspace
   switch/create.
3. **Notebook** — `App::NotebookController#index` (route `get "notebook"`) renders
   `notebook/Index` with `folders`, `notes` (+ `folderId`), `categories`, `tags`. Add
   `folderId` to `note_json`. New page `pages/notebook/Index.tsx`: folder rail (All notes +
   per-folder counts) + searchable/filterable note cards + "New note". Request spec.
4. **Dashboard** — controller adds `dueCount` + `recentNotes`; `pages/Dashboard.tsx` becomes
   the Tatami home: greeting + streak, continue-watching grid, daily-review card, recent
   notes.
5. **Verify** — `rspec` green (incl. new notebook spec), `tsc` clean, `vite build` ok,
   `rubocop` clean.

## Exit criteria

- [x] App-wide palette + type is Tatami (cream/ember, Fraunces/Hanken) on every authenticated
      page, via the theme remap (`application.css` `@theme`).
- [x] AppShell shows the top bar + left sidebar with grouped nav and active highlighting.
- [x] Nav has a single **Notebook** entry; `/notebook` renders folders + notes; `/notes` and
      `/folders` still work.
- [x] Dashboard renders the Tatami home with real continue-watching, due count, recent notes.
- [x] `rspec` (123 ex, incl. `spec/requests/notebook_spec.rb`), `tsc`, `vite build`, `rubocop`
      all green.

## What shipped

- `app/frontend/entrypoints/application.css` — fonts + `@theme` remap (neutral→warm stone,
  amber→ember) + `ember/gold/teal/ink/paper/surface` tokens + `font-display`.
- `app/frontend/components/AppShell.tsx` — v2 top bar + left sidebar, grouped nav with
  **Notebook**, active highlighting, `dueCount`/`streakDays` badges, workspace switcher kept.
- `app/controllers/app/notebook_controller.rb` + route `get "notebook"` + `note_json` gains
  `folderId`; `app/frontend/pages/notebook/Index.tsx` (folder rail + searchable note cards).
- `app/controllers/app/base_controller.rb` — global `dueCount` in `inertia_share`.
- `app/controllers/app/dashboard_controller.rb` + `pages/Dashboard.tsx` — Tatami home.
- `spec/requests/notebook_spec.rb` — lists/filters notes & folders.

## Out of scope (follow-up iterations)

- Bespoke Tatami reskins of `videos/Show` (the YouTube watch layout + floating notes panel),
  `courses/Show`, and the library/search grid beyond what the theme remap provides.
- Review session screen, Training log, Positions graph bespoke layouts.
- Renaming the `Note`/`Folder` models or routes (kept as-is; "Notebook" is presentation).
- Command palette (Direction C) and other directions.
