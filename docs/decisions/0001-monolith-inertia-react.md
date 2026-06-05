# ADR 0001 — Monolith Rails + Inertia/React (not API + separate SPA)

- **Status:** Accepted
- **Date:** 2026-06-04
- **Decision owner:** Frank Zhu

---

## Context

method-channel (our reference app) is an **API-only** Rails app: it exposes JSON over
`/api/v1/...`, authenticates with **Devise + JWT**, serializes with Active Model
Serializers, documents with rswag, and is consumed by a **separate** frontend over CORS.

Pinpoint is a single product with a single web client. We do not (yet) have native mobile
apps or third-party API consumers that would justify a standalone public API and the
overhead of versioning, serializers, token auth, and CORS.

## Decision

Build Pinpoint as a **monolithic Rails app** that renders the frontend with
**Inertia.js + React + Vite** (`inertia_rails`, `vite_rails`). Controllers return Inertia
responses (`render inertia: "Page", props: {...}`), not JSON envelopes. Authentication is
**session/cookie-based Devise** — **no JWT**.

This means, relative to method-channel, we **drop**: `devise-jwt`, `active_model_serializers`,
`rswag-api` / `rswag-ui`, `rack-cors`, the `/api/v1` namespace, and the serializer-resolution
convention. We **keep** Devise itself, the authorization layer (Action Policy — ADR 0008),
and the rest of the domain stack (see
ADR 0007).

## Consequences

- ✅ One codebase, one deploy, no CORS, no token plumbing. Props are computed server-side
  and passed straight to React — no serializer layer to maintain.
- ✅ Server-driven routing/auth/authorization; Action Policy runs in the controller exactly as
  in a classic Rails app.
- ✅ Direct upload to Active Storage / Aliyun still works (it's a browser→storage flow,
  independent of API-vs-Inertia).
- ⚠️ No ready-made public JSON API. If native mobile or third-party integrations are needed
  later, we add a **separate** `/api` namespace then (Inertia and a JSON API can coexist) —
  that is a future ADR, not a reason to go API-first now.
- ⚠️ Props are not serializers. We will need a lightweight, consistent way to shape props
  (plain Ruby hashes, possibly `alba` or `blueprinter` for reusable shapes) — decided per
  the model/serializer guide, not here.
- ⚠️ Inertia is stateful-per-page; heavy realtime UI (if any) uses Action Cable directly.

## Alternatives considered

- **API-only + separate React SPA (method-channel's model).** Rejected: doubles the
  surface (two repos, CORS, JWT refresh, serializer maintenance, API versioning) for a
  single first-party client. The cost buys flexibility we don't need yet.
- **Hotwire/Turbo + Stimulus (Rails default).** Rejected: the UI (video player synced to a
  notes timeline, drag-to-reorder curricula, review sessions) is genuinely
  application-like and benefits from React's component model and client state. The default
  gems stay installed but unused for app screens; the marketing site may use plain
  views/Turbo.

## Sources

- Inertia Rails: <https://inertia-rails.dev/>
- Vite Rails: <https://vite-ruby.netlify.app/>
