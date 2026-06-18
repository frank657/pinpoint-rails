# Iteration 0008 — UUID primary keys everywhere

> **Status:** ✅ **Shipped (dev + test)** — locked by **ADR 0012** ·
> **Owner:** Frank · **Started:** 2026-06-17 · **Shipped:** 2026-06-18
>
> **Decision taken:** Path **B (in-place, preserve data)**, **dev + test only** — production is
> rolled out separately by the owner (dump → migrate → smoke test).
>
> **Done:** every bigint PK + FK + polymorphic id converted to uuid in place, data preserved
> (migration `20260618110000_convert_primary_keys_to_uuid`); the `taggable_id::bigint` /
> `map(&:to_i)` workarounds removed; athlete-avatar Active Storage attach now works; frontend ids
> retyped `number → string`. Default-workspace resolution fixed to `order(:created_at)` (uuid `.first`
> is no longer chronological). Green: `rspec 177/0`, `tsc`, `vite build`, `rubocop`; live page verified.
>
> **Production rollout (owner, not done here):** maintenance window, fresh dump first, run the
> migration, run the smoke test; roll back by restoring the dump (migration is irreversible).

## Goal

Two things:
1. **Future tables default to UUID** primary keys (Rails generator + new migrations).
2. **Convert all existing bigint PKs (and every FK referencing them) to UUID.**

## Why this is big and risky
Today most tables already considered "content" are UUID (`notes`, `video_segments`, `vods`,
`shares`/`forks` polymorphic targets). The **bigint** PKs remaining: `users`, `workspaces`,
`workspace_memberships`, `videos`, `categories`, `tags`, `positions`, `techniques`, `athletes`,
`progresses`, and the join tables (`note_tags`, `note_positions`, `note_techniques`,
`note_categories`, `video_athletes`, `taggings`) + their FKs (`video_id`, `category_id`,
`workspace_id`, `user_id`, …) scattered across nearly every table.

Converting a PK type means: add a new uuid column, backfill, repoint every FK, swap, re-add
indexes/constraints — table by table, in dependency order. On a live Postgres this **rewrites
every table** and **cannot be zero-downtime** without heavy choreography.

## What it would simplify (real upside)
- The polymorphic **`Tagging.taggable_id`** could become a true `uuid` column (today it's a
  workaround because notes are uuid but other taggables aren't) — removing the `note_ids_for_tag`
  string-join hack in `NotesController`.
- `note_categories.category_id`, `video_athletes`, etc. become uniform uuid — no mixed-type joins.
- One consistent id type app-wide; no "is this uuid or bigint?" guessing (and `Share`/`Fork`'s
  string `source_id`/`target_id` become clean).

## Approach — pick one (this is the go decision)
- **(A) Fresh UUID schema + reseed — recommended given this is a low-data beta.** Author a clean
  schema with `id: :uuid` everywhere, drop & recreate the dev/prod databases, re-seed. Simplest
  and least error-prone *because there's little real data to preserve*. Production impact = a
  rebuild (acceptable on a single-user beta with a maintenance window). Verify what prod data
  actually matters first.
- **(B) In-place conversion migrations.** Per-table: add `uuid` col, backfill, repoint FKs, swap
  PK, rename. Preserves data but is large, slow, and needs a maintenance window (not zero-downtime).
- **(C) Gradual / leave existing, UUID only for new tables.** Lowest risk, but leaves the DB
  permanently mixed — contradicts "change all existing."

## Future-default setup (independent of A/B/C, low risk — can do anytime)
- Enable `pgcrypto`/`gen_random_uuid()` (already used by notes/segments).
- `config/initializers/generators.rb`: `g.orm :active_record, primary_key_type: :uuid`.
- New migrations: `create_table :x, id: :uuid`; references `type: :uuid`.
- Update `models-guide.md` to state UUID is the default PK.

## Production safety (the hard constraint)
Neither (A) nor (B) is zero-downtime. Required: a **maintenance window**, a **full backup/dump
first**, a tested **rollback** (restore the dump), and the **post-deploy smoke test** from 0007.
Confirm what production data must survive — if little/none, (A) is dramatically safer than (B).

## Exit criteria (once a path is chosen)
- [ ] Every table's PK is `uuid`; every FK is `uuid`; no bigint ids remain (schema grep).
- [ ] Generator + new-migration default is uuid; `models-guide.md` updated.
- [ ] `Tagging.taggable_id` is uuid; the string-join workaround removed; tag filtering still works.
- [ ] Full green gate; **migrations/rebuild reversible from a dump**; production smoke test passes.

## Decision needed before any code
1. **Path A (fresh schema + reseed) vs B (in-place convert)?** — recommend **A** (beta, low data).
2. **Is there production data that must be preserved?** (drives A-vs-B and the backup plan.)
3. OK to enable the **UUID generator default now** (the low-risk half), independent of the conversion?
