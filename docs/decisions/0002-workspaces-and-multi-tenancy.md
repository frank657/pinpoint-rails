# ADR 0002 — Workspaces as the multi-account / tenancy boundary

- **Status:** Accepted
- **Date:** 2026-06-04
- **Decision owner:** Frank Zhu

---

## Context

Requirement: *"users can have multiple accounts, where each account is for them to manage a
specific topic."* A user studying BJJ, guitar, and cooking wants those worlds kept
separate — separate videos, courses, notes, categories, and review queues — under one
login, switchable like Notion/Slack.

method-channel already uses `acts_as_tenant`, scoped to its `Creator` model. We adopt the
same mechanism with a different tenant.

## Decision

The tenancy boundary is the **Workspace**. One **User** (a single login / Devise identity)
belongs to **many** Workspaces through **WorkspaceMembership**; a Workspace has many members
(enabling future collaboration). Almost every domain model is
`acts_as_tenant :workspace` — Video, Course, Curriculum, Note, Category, Tag, Folder,
Segment, Chapter, and the per-user learning tables are all workspace-scoped.

- The **current workspace** is resolved per request (from the session, switched via a
  workspace picker) and set as the acts_as_tenant current tenant in a `before_action`.
- "Switch workspace" changes the active tenant; the URL/app context follows.
- A User always has at least one Workspace (created on signup, e.g. "Personal").
- **Sharing/forking crosses workspace boundaries** (see ADR 0005): I can share a Course
  from my "BJJ" workspace and you fork it into your "Grappling" workspace.

The word presented to users is **"Workspace"** (the chip/switcher says *Switch workspace*).
Internally the model is `Workspace`.

## Consequences

- ✅ Hard data isolation per topic with one login; `acts_as_tenant` auto-scopes queries so
  cross-topic leakage is structurally prevented.
- ✅ Multi-member workspaces are available later for free (the join model exists from day
  one) without a migration.
- ✅ Maps cleanly onto subdomains/routing and onto per-user learning state (review queues
  are naturally per (user, workspace)).
- ⚠️ **Every** tenant query needs a current tenant set, or it raises / returns nothing.
  Background jobs and webhooks must set the tenant explicitly (`ActsAsTenant.with_tenant`).
  Aliyun VOD webhooks arrive without a session — resolve the workspace from the Vod/Video
  record, not the request.
- ⚠️ Global/cross-tenant tables (User, WorkspaceMembership, Workspace itself, Share links,
  admin tables) must **not** be `acts_as_tenant` — be deliberate about which side each
  model is on.
- ⚠️ Uniqueness constraints become per-workspace (e.g. a Category name is unique within a
  workspace, not globally) — scope unique indexes by `workspace_id`.

## Alternatives considered

- **Profiles (one account, switchable view filter).** Rejected: weaker isolation, and
  ownership/sharing boundaries get muddy because all data lives in one pool tagged by
  profile. Retrofitting true isolation later is painful.
- **Separate logins per topic.** Rejected: defeats "one user, many topics"; forces
  re-auth and fragments identity, billing, and cross-topic sharing.
- **Single account + folders only.** Rejected: doesn't satisfy the "separate account per
  topic" requirement; folders still exist (ADR 0003) but as *intra*-workspace note
  organization, not the isolation boundary.

## Sources

- acts_as_tenant: <https://github.com/ErwinM/acts_as_tenant>
