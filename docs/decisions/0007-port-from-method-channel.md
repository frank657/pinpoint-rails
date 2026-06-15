# ADR 0007 — What to port from method-channel vs. drop/replace

- **Status:** Accepted
- **Date:** 2026-06-04
- **Decision owner:** Frank Zhu

---

## Context

Pinpoint is built "like method-channel" for services/libs/gems, but as a **monolith**
(ADR 0001), not an API app. This ADR records — with the owner's confirmation — exactly which
method-channel subsystems we **port**, **defer**, or **drop/replace**, so the boundary is
explicit and we don't drag along API-era baggage.

method-channel reference path:
`/Users/frankzhu/code/projects/bjj/method-channel/method-channel-rails`.

## Decision

### PORT NOW (copy & adapt)

| Subsystem | What to bring | Notes |
|-----------|---------------|-------|
| **Aliyun VOD pipeline** | `app/lib/ali_vod/**`, `app/services/vod_service/**`, `Vod` + `Vod::Attachment` models, `Vod::Providers` concern, `vod_attached` macro, the Aliyun VOD webhook controller, `config/storage.yml`, `config/initializers/activestorage_aliyun_patch.rb` | The crown jewel. Provision credentials → browser direct-uploads to OSS → webhooks flip `uploading→uploaded→ready`. Adapt webhook to resolve workspace from the Vod (no session). |
| **Active Storage direct upload** | direct-upload flow + Aliyun service patch (signed private URLs) | Used for rich-text note images and cover images. |
| **Auth: Devise** | Devise core | **Session-based, drop JWT** (ADR 0001). Keep third-party-auth structure only if/when needed. |
| **Authorization** | ~~CanCanCan~~ → **Action Policy** (per-resource policy classes) | Superseded by ADR 0008 — CanCanCan is NOT ported. |
| **Background jobs** | Sidekiq + Sidekiq Cron, Solid Queue, multi-DB (primary/queue/cache/cable) | Same setup. |
| **acts_as_tenant** | tenancy mechanism | Tenant = **Workspace**, not Creator (ADR 0002). |
| **FriendlyId** | slugs | Workspaces, public share pages. |
| **pg_search** | full-text search | Notes. |
| **Kaminari** | pagination | — |
| **Noticed** | notifications | "someone forked your video". (Owner opted in.) |
| **PaperTrail** | audit / version history | Note edit history, undo. (Owner opted in.) |
| **Mobility** | i18n (en/zh) | Content + UI translation. (Owner opted in.) |
| **Testing** | RSpec + FactoryBot + shoulda-matchers + faker | Same structure; stub Aliyun in specs. |
| **Deployment** | Kamal + Thruster + multi-stage Dockerfile (Ruby 3.3.2-slim, Aliyun mirrors) | Adapt hosts/domains for the three subdomains. |
| **Image processing** | image_processing + ruby-vips | Variants for note images/covers. |
| **Dev tooling** | dotenv-rails, brakeman, rubocop-rails-omakase, pry, prosopite (N+1), awesome_print, letter_opener | Same. |

### ADD NEW (not in method-channel)

- **Inertia.js + React + Vite** (`inertia_rails`, `vite_rails`) — the frontend (ADR 0001).
- **Tailwind CSS** — styling.
- **YouTube ingestion** — oEmbed/metadata — Phase 2.

> Earlier plans also added FSRS spaced-repetition and a Transcript + AI provider; both were
> later removed (see `../roadmap/DEVELOPMENT_PLAN.md`).

### DROP / REPLACE (API-era, not needed in a monolith)

| Dropped | Why |
|---------|-----|
| `devise-jwt` | Session auth instead (ADR 0001). |
| `active_model_serializers` | Inertia props replace JSON serializers. A light prop-shaping helper may be added (model/serializer guide), not AMS. |
| `rswag-api`, `rswag-specs`, `rswag-ui` | No public OpenAPI surface. |
| `rack-cors` | No cross-origin API. |
| `/api/v1` namespace + manager/creator serializer split | Replaced by app/admin subdomain controllers (ADR 0006). |

### DEFER (out of scope for v1, revisit with its own ADR)

| Deferred | Why |
|----------|-----|
| **Stripe / payments / money-rails / Stripe Connect** | Not in the initial product. method-channel's entire payments/entitlement/payout/refund stack is **not** ported. If monetization (paid courses, marketplace) is added, it gets its own ADRs — see method-channel ADR 0001 for how deep that rabbit hole goes. |
| **Chat (Chat::Group/Direct/Message + cable)** | Not a learning-core feature; revisit if collaboration demands it. |
| **WeChat / Apple third-party auth** | Add when a real login channel needs it. |

## Consequences

- ✅ We inherit a battle-tested video pipeline and ops setup without re-deriving them.
- ✅ The monolith sheds the API/serializer/JWT/CORS layer cleanly.
- ⚠️ Porting the Aliyun code requires re-wiring tenancy (Workspace) and removing the
  Creator/payments assumptions baked into method-channel's `Vod` neighbors — port the VOD
  core, not its surrounding monetization context.
- ⚠️ Noticed, PaperTrail, and Mobility each add schema + maintenance surface; they were
  explicitly opted into and are scheduled in later phases, not all in Phase 0.

## Sources

- method-channel exploration notes (this repo's research) and method-channel
  `docs/` + `Gemfile`.
