# Phase 1 — Auth & Workspaces

**Goal:** users can sign up / log in (session-based Devise) on `app.`, land in a
**Workspace**, and create/switch between multiple workspaces (one per topic). Tenancy is
live: every later model scopes to the current workspace.

**Depends on:** Phase 0 · **Locked by:** ADR 0002 (workspaces/tenancy), 0006 (subdomains)

## Scope

### Auth (Devise, session-based — no JWT, ADR 0001)
- `User` model via Devise: `database_authenticatable`, `registerable`,
  `recoverable`, `rememberable`, `validatable`. `admin:boolean default false`.
- Sign up / in / out / password reset, rendered as Inertia pages on `app.`.
- Cookie/session config shared across subdomains (ADR 0006) so `app.` login is usable by
  apex/admin gates; verify with a request spec.

### Workspaces (ADR 0002)
- `Workspace` (`name`, `slug` FriendlyId) and `WorkspaceMembership`
  (`user_id`, `workspace_id`, `role:enum { owner, member }`).
- On signup, auto-create a default workspace (e.g. "Personal") and an `owner` membership.
- Workspace CRUD: create, rename, list mine, delete (guard last-workspace).
- **Switcher**: set `current_workspace` in the session; a `before_action` in
  `App::BaseController` resolves it and calls `ActsAsTenant.current_tenant = ...`.
- `acts_as_tenant :workspace` wired and ready (no tenant models yet beyond membership, but
  the mechanism + the `current_tenant` resolution is in place and tested).

### Authorization
- Action Policy `ApplicationPolicy` + `WorkspacePolicy` (ADR 0008); a user can only act
  within workspaces they belong to.
- Guard: tenant queries with no current tenant raise (catch misconfig early).

### Frontend
- Auth pages (Inertia/React), an app shell with the **workspace switcher** chip, and an
  empty dashboard ("no videos yet").

## Key tasks
1. Devise install + User model + Inertia auth screens + subdomain cookie config.
2. Workspace + WorkspaceMembership models, factories, specs.
3. Default-workspace-on-signup; workspace CRUD + switcher; session-based current tenant.
4. `acts_as_tenant` resolution in `App::BaseController`; misconfig guard.
5. Action Policy + membership-scoped authorization; request specs for cross-workspace
   access denial.

## Out of scope
- Any content models (videos/notes); admin panel (Phase 6); sharing across workspaces
  (Phase 5).

## Exit criteria
- Sign up → land in "Personal" workspace; create a 2nd workspace; switch between them; the
  active workspace persists across requests.
- `ActsAsTenant.current_tenant` is set on every `app.` request; a tenant query without it
  raises (covered by a spec).
- A user cannot read/act on a workspace they don't belong to (request spec proves the 403).
- One login works across `app.` and the apex; admin gate still blocks non-admins (stub).
