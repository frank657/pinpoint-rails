# ADR 0008 — Authorization via Action Policy (not CanCanCan)

- **Status:** Accepted
- **Date:** 2026-06-04
- **Decision owner:** Frank Zhu

---

## Context

method-channel uses **CanCanCan** (a single `Ability` class per namespace). Pinpoint's
authorization is **resource- and tenant-centric**: "may this user act on this Workspace /
Course / Note?" almost always reduces to membership + ownership within a Workspace
(docs/decisions/0002), and admin is a separate surface (docs/decisions/0006).

For that shape, **per-resource policy objects** scale better than one growing `Ability`
god-class, and pair naturally with the three-axis model (each content/taxonomy resource
gets its own policy).

## Decision

Use **Action Policy** (`action_policy`) as the authorization layer instead of CanCanCan.

Conventions for this app:

- Policies live in `app/policies/`, one per resource: `ApplicationPolicy` (base, **default
  deny**) → `WorkspacePolicy`, later `CoursePolicy`, `NotePolicy`, etc.
- The authorization **context is the signed-in `User`**, declared once in
  `ApplicationController`:
  ```ruby
  include ActionPolicy::Controller
  authorize :user, through: :current_user
  ```
- Controllers call `authorize! record, to: :rule?`; `ActionPolicy::Unauthorized` is rescued
  to a **403** in `ApplicationController`.
- Use `alias_rule` to collapse related rules (e.g. `show?/update?/destroy? → manage?`).
- Use `relation_scope` (Action Policy scoping) to filter index queries to what the user may
  see — complementary to `acts_as_tenant`, which already scopes by workspace. (Tenant
  scoping is the coarse cut; policy scopes are the fine cut.)
- Rules read from the policy's `user` and `record`; tenancy is assumed already applied by
  `acts_as_tenant` (the current workspace), so policies mostly check membership/role and
  ownership, not "which workspace".

## Consequences

- ✅ Authorization logic is colocated with each resource and unit-testable in isolation
  (Action Policy has first-class RSpec matchers: `be_an_alias_of`, `have_authorized_scope`,
  `permit`/`forbid`).
- ✅ Default-deny base policy makes "forgot to authorize" fail closed.
- ✅ Plays well with multi-tenancy: policies + `acts_as_tenant` separate "which workspace"
  (tenant) from "may this member do this" (policy).
- ✅ Explicit `authorize!` per action keeps controllers readable; no implicit `load_and_authorize`.
- ⚠️ Every controller action that touches a protected resource must call `authorize!` (or
  `authorized_scope`) — there is no global auto-authorize. A test/convention guards this
  (consider `verify_authorized` in a future iteration).
- ⚠️ Team must learn Action Policy idioms (pre-checks, aliases, scopes) instead of CanCanCan's
  `can`/`cannot` DSL.

## Supersedes

The CanCanCan row in **ADR 0007** (port list). CanCanCan is **not** used. ADR 0007 updated
to reflect this.

## Sources

- Action Policy: <https://actionpolicy.evilmartians.io/>
- Testing policies (RSpec): <https://actionpolicy.evilmartians.io/#/testing>
