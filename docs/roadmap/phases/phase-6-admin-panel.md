# Phase 6 — Admin panel

**Goal:** an admin-only panel on `admin.pinpoint.com` to manage users, workspaces, videos,
and content — for support, moderation, and operational visibility.

**Depends on:** Phase 1 (can be built in parallel with 2–5 once auth exists) ·
**Locked by:** ADR 0006 (subdomain + server-side admin authz)

## Scope

### Access & security (ADR 0006)
- Lives under the `admin.` subdomain (routing constraint from Phase 0).
- **Defense in depth:** subdomain **plus** a `before_action` requiring `current_user.admin?`
  (or an Action Policy rule) on **every** admin action. Subdomain alone is never the gate.
- Audit admin actions (PaperTrail / a simple admin action log).
- Consider IP allowlist / separate proxy in front of `admin.` at deploy time.

### Frontend
- Inertia + React admin shell (distinct layout from `app.`).
- Dashboards: counts/health (users, workspaces, videos, storage, jobs).

### Management surfaces
- **Users:** search, view, disable/enable, grant/revoke admin, impersonate (optional, audited).
- **Workspaces:** list, inspect membership, soft-delete.
- **Videos/Vods:** list, inspect Aliyun status, re-trigger transcode/cover, force-delete
  (respecting Vod reference counts, ADR 0005).
- **Content moderation:** view reported/public shares; unpublish a public share.
- **Jobs/ops:** Sidekiq/Solid Queue visibility (mount a guarded dashboard).

## Key tasks
1. Admin auth gate (subdomain + `admin?` + ability) + admin base controller + layout.
2. Admin Inertia pages: dashboard, users, workspaces, videos, shares.
3. Cross-tenant admin reads (admin operates across workspaces — uses
   `ActsAsTenant.without_tenant` / explicit scoping, carefully).
4. Action audit log; guarded Sidekiq/queue dashboard mount.
5. Request specs proving non-admins get 403 on every admin route, even on the `admin.`
   subdomain.

## Out of scope
- Billing/payouts admin (no payments in v1, ADR 0007).
- End-user-facing features.

## Exit criteria
- A non-admin hitting any `admin.` route gets 403 (spec covers the whole namespace).
- An admin can list/search users and workspaces across tenants, disable a user, and inspect
  a Vod's Aliyun status.
- Admin actions are audited.
- Cross-tenant admin reads don't leak one workspace's data into another's app view (the
  app side still scopes by tenant).
