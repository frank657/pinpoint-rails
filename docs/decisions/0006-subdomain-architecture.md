# ADR 0006 — Subdomain layout (landing / app / admin)

- **Status:** Accepted
- **Date:** 2026-06-04
- **Decision owner:** Frank Zhu

---

## Context

Requirement: *"routes will be `appname.com` for the landing page; `app.appname.com` to enter
as a user; `admin.appname.com` to enter as admin."* Three audiences (visitor, authenticated
user, admin) with different auth, layouts, and risk profiles.

(The production domain is TBD; `pinpoint.com` is used illustratively below. The brand name
is **Pinpoint**.)

## Decision

Three host roles, separated by **subdomain constraints** in routing:

| Host | Audience | Auth | Frontend |
|------|----------|------|----------|
| `pinpoint.com` (apex + `www`) | Public visitors | none | Marketing/landing (server views or a light Inertia/Vite bundle) |
| `app.pinpoint.com` | Authenticated users | Devise session | Inertia + React (the product) |
| `admin.pinpoint.com` | Admins/staff | Devise session + admin authorization | Inertia + React (admin panel) |

Implementation:
- A routing constraint splits the three. Use `constraints(Subdomain.new("app"))` /
  `Subdomain.new("admin"))` (a small custom constraint) or `config/routes/*.rb` files drawn
  under host constraints — mirror method-channel's split-routes layout.
- **Workspaces are NOT subdomains.** The current workspace (ADR 0002) is part of the
  in-app session/state under `app.`, not encoded in the host. (Per-workspace subdomains are
  a possible future ADR; not now — it complicates cookies, SSL, and sharing.)
- **Cookies/sessions** are configured to be shared across subdomains where needed
  (`:domain => :all` or `.pinpoint.com`) so a single Devise login works on `app.` and the
  apex; **admin is a separate authorization gate** even if the session cookie is shared.
- Admin is defended in **depth**: subdomain + a `before_action` requiring `current_user.admin?`
  (or an `Admin` role / Action Policy rule), never subdomain alone.
- Local dev uses `lvh.me` / `*.localhost` (e.g. `app.lvh.me:3000`, `admin.lvh.me:3000`)
  which resolve to 127.0.0.1, so subdomain routing works without `/etc/hosts` edits.

## Consequences

- ✅ Clean separation of public, app, and admin surfaces; admin can be locked down at the
  edge (IP allowlist / separate proxy) independently of the app.
- ✅ Marketing pages stay cacheable/SEO-friendly on the apex, decoupled from the app bundle.
- ⚠️ Subdomain cookie config is fiddly; get the cookie `domain` right early or login breaks
  across hosts. Cover with a request spec.
- ⚠️ Vite/Inertia must serve correct asset hosts per subdomain; CSP and asset_host need to
  account for `app.` and `admin.`.
- ⚠️ Admin authorization must be enforced server-side on every admin action — the subdomain
  is a routing convenience, not a security boundary.

## Alternatives considered

- **Path-based (`/admin`, `/app`) on one host.** Simpler cookies, but weaker isolation and
  doesn't match the requested layout; harder to put admin behind separate network controls.
- **Per-workspace subdomains (`bjj.pinpoint.com`).** Rejected for now: multiplies SSL/cookie
  complexity and complicates cross-workspace sharing; workspace is in-app state instead.
