# Models Guide

How we write models and set up their tables in Pinpoint. Read this before adding a model,
a column, or a migration. It encodes conventions that are easy to get subtly wrong (tenancy,
the three-axis split, namespacing) and that the ADRs lock in.

The two rules that override everything else:

1. **Decide the axis before you add anything** (content / taxonomy / per-user state — ADR 0004).
2. **Namespace a model under its parent when it only exists in relation to that parent**
   (e.g. `Video::Segment`). This is a standing preference — see below.

---

## 1. Which axis? (ADR 0004 — decide first)

Every model and every column belongs to exactly one of three axes. Put it in the wrong one
and forking, sharing, and privacy all break. Decide before you write the migration.

| Axis | What it is | Examples | Forking rule |
|---|---|---|---|
| **1 — Content** | Shared & forkable material | `Video`, `Video::Segment`, `Note` | deep-copied |
| **2 — Taxonomy** | Labels / curated structure | `Category`, `Tag`, `Position`, `Technique` | re-pointed by name |
| **3 — Per-user state** | Private, never shared | `Progress` | never copied |

- **Per-user state never goes on a content table.** No `last_viewed_at` on `Video`; it goes on
  `Progress`, keyed by `(user, workspace, trackable)`. If you're tempted to add a user-specific
  column to a content row, you want a row on an Axis-3 table instead.
- **Timestamps into media are numeric seconds (floats), never formatted strings.** A range is an
  optional `[start_seconds, end_seconds]` pair (see `Note`, `Video::Segment`).

## 2. Namespacing — the standing preference

**If a model only makes sense in relation to a parent resource, nest it under that parent.**
A `Segment` is always a segment *of a video*; it is `Video::Segment`, not `Segment`. A
membership is always *of a workspace*; it is `Workspace::Membership`. This keeps the domain
legible and groups related files together.

Use a top-level name only when the model stands on its own (`Video`, `Note`, `Category`,
`Tag`, `Position`) or is intentionally cross-cutting (`Progress` is polymorphic across
trackables, so it is **not** `Video::Progress` — nesting it would hide that it serves many
parents).

### How to write a nested model

A nested model's table is its **full underscored name** (`video_segments`, `workspace_memberships`)
— not the demodulized one. Set `self.table_name` explicitly (the parent is itself a table, and
**do not** use `table_name_prefix` — it also rewrites the parent's own table).

```ruby
# app/models/video/segment.rb
class Video::Segment < ApplicationRecord
  self.table_name = "video_segments"   # full underscored name; matches Workspace::Membership →
                                       # workspace_memberships. Set explicitly (ADR 0011).
  acts_as_tenant :workspace
  belongs_to :video
end
```

Things that follow from the namespace — get all of them:

- **File path** mirrors the constant: `app/models/video/segment.rb`.
- **Association `class_name`**: the parent's `has_many` must name the namespaced class —
  `has_many :segments, class_name: "Video::Segment", dependent: :destroy`.
- **Policy** follows the model: `Video::SegmentPolicy` in `app/policies/video/segment_policy.rb`
  (Action Policy resolves `record.class` → `"#{class}Policy"`).
- **Factory** must name the class: `factory :segment, class: "Video::Segment" do … end`.
- **Table name**: the full underscored name (`video_segments`, `workspace_memberships`), set via
  `self.table_name` explicitly.

## 3. Tenancy (ADR 0002)

- **Every workspace-owned model gets `acts_as_tenant :workspace`** (Axis 1 and Axis 2). Axis-3
  state belongs to a `(user, workspace)` pair and uses plain `belongs_to :workspace` +
  `belongs_to :user` with a uniqueness scope.
- Never query a tenant model without a current tenant set. In jobs/webhooks that run without a
  tenant, re-enter one: `ActsAsTenant.with_tenant(workspace) { … }`.
- Cross-tenant reads (forking reads the source subtree) use `ActsAsTenant.without_tenant { … }`.

## 4. Model body conventions

Grounded in the existing models — match them.

- **Enums are integer-backed with a `prefix`:** `enum :category, { guard: 1, … }, prefix: :category`
  (see `Position`). Prefixing avoids scope collisions across models.
- **Uniqueness is scoped to the workspace, case-insensitive** for name-like columns:
  `validates :name, uniqueness: { scope: :workspace_id, case_sensitive: false }` (see `Tag`, `Position`).
- **Self-referential trees** use `belongs_to :parent, class_name: "Self", optional: true` +
  `has_many :children, foreign_key: :parent_id, dependent: :nullify` (see `Position`).
- **Full-text search** is pg_search: `include PgSearch::Model` + a `pg_search_scope` (see `Note`).
- **Order scopes live on the model**, sorted by the numeric/position columns:
  `scope :for_video, ->(v) { where(video: v).order(:position, :start_seconds) }`.
- Validate invariants in the model (`end_after_start`), not the controller.

## 5. Migrations & the database

- **Multi-database** (ADR / config): primary + `queue` + `cache` + `cable` per env. App tables
  go in **primary**. Don't add app tables to the Solid databases.
- **Reversible drops.** When removing a feature, write `up`/`down` so `down` recreates the table
  exactly as the original `create_*` migration did — see `DropReviewCards`, `DropTranscriptLines`.
  This keeps the migration reversible and documents what was removed.
- **UUID primary keys are the default** (iteration 0008). New tables: `create_table :x, id: :uuid`;
  references: `t.references :y, type: :uuid, foreign_key: true`. The generator default is set in
  `config/initializers/generators.rb`. (Some legacy tables are still bigint pending the 0008
  conversion — when adding a FK to one, match its current key type.)
- **Foreign keys + indexes:** add the reference + an index on any column you'll filter/sort by
  (`add_index :video_segments, %i[video_id start_seconds]`).
- **Numeric seconds** are `t.float`, with `null: false` on the required bound.
- After migrating, both dev and test must be updated: `bin/rails db:migrate` then
  `bin/rails db:test:prepare`. `db/schema.rb` is the source of truth — commit it with the migration.

## 6. Checklist for a new model

- [ ] Axis decided (content / taxonomy / per-user state).
- [ ] Namespaced under its parent if it only exists in relation to one (`Parent::Child`,
      `self.table_name` set explicitly, file path mirrors the constant).
- [ ] `acts_as_tenant :workspace` (or the `(user, workspace)` pattern for Axis 3).
- [ ] Associations declare `class_name`/`foreign_key` where the namespace requires it.
- [ ] Policy (`Parent::ChildPolicy`) + factory (`class: "Parent::Child"`) created.
- [ ] Migration: FKs, indexes, numeric seconds, reversible; `schema.rb` committed.
- [ ] Specs first (model spec at minimum) — see `testing-guide.md`.
