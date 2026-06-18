# ADR 0012 — UUID primary keys everywhere

- **Status:** Accepted
- **Date:** 2026-06-18
- **Decision owner:** Frank Zhu
- **Supersedes/closes:** iteration 0008

---

## Context

The schema grew with mixed primary-key types. Content created later (`notes`, `video_segments`,
`vods`) used **uuid** PKs; everything earlier (`users`, `workspaces`, `videos`, the taxonomy
tables, the join tables, `progresses`, `shares`, `forks`, `taggings`, `versions`) used **bigint**.

That split forced workarounds and blocked features:

- **Polymorphic columns couldn't be SQL-joined.** `taggings.taggable_id` was a **string** holding
  both a Note uuid and a Video bigint, so tag filtering needed `taggable_id::bigint` casts and
  `pluck(...).map(&:to_i)` shims rather than a clean join.
- **Active Storage / Action Text were unusable on bigint records.** Both ship with a `uuid`
  `record_id`, so an athlete avatar (Active Storage) or a video description via `has_rich_text`
  (Action Text) could not attach to a bigint-keyed row.
- Constant "is this id a uuid or a bigint?" friction across models, serializers, and the frontend.

## Decision

**Every table's primary key is `uuid`, and every foreign key / polymorphic id that references one
is `uuid`.** New tables default to uuid (generator config, `models-guide.md`).

- Existing data was migrated **in place, preserving rows** (not a drop-and-reseed): each bigint
  PK got a fresh `gen_random_uuid()`, every FK was backfilled by joining on the old ids, and the
  polymorphic ids (`taggings.taggable_id`, `shares.shareable_id`, `forks.source_id`/`target_id`,
  `progresses.trackable_id`, `versions.item_id`) were rewritten/retyped to uuid. See migration
  `20260618110000_convert_primary_keys_to_uuid`.
- **Framework-internal tables stay bigint:** `active_storage_*` and `action_text_rich_texts` keep
  their own bigint PKs — their polymorphic `record_id` is already uuid and points at our records
  correctly; converting their internal keys buys nothing and risks breaking the gems.
- `pgcrypto` (`gen_random_uuid()`) is the id source.

## Consequences

- **Workarounds removed.** `taggable_id` is a real uuid → `Video.with_tag`, the search controller,
  and tag filtering join directly, no casts.
- **Features unblocked.** Athlete avatars attach via Active Storage; video descriptions can move to
  Action Text (`has_rich_text`) if richer-than-HTML editing is wanted.
- **Integer URLs change.** Records are addressed by uuid, so old `/videos/4`-style links no longer
  resolve. Acceptable for the beta; anything needing stable human URLs should use FriendlyId slugs.
- **`.first`/`.last` no longer mean "oldest/newest".** Implicit PK ordering was chronological with
  bigint; with uuid it is random. Code that wanted the oldest row must `order(:created_at)`
  explicitly (fixed in `App::BaseController#resolve_current_workspace` and
  `WorkspacesController#destroy`). **This is the standing gotcha to watch for.**
- **Not zero-downtime.** The in-place conversion rewrites every table; production must run it in a
  maintenance window with a fresh dump taken first and a tested restore as rollback (the migration
  is `IrreversibleMigration` — roll back by restoring the dump).

## Alternatives considered

- **Fresh schema + reseed** — simpler, but destroys existing rows; rejected to preserve data.
- **Leave the split, uuid only for new tables** — lowest effort, but permanently keeps the
  string-id workarounds and the Active Storage/Action Text block; rejected.
