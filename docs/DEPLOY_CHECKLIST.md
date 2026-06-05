# Deploy Checklist

> Stub created in Phase 0. Fleshed out when we first deploy (post-MVP). Pinpoint deploys
> via **Kamal + Docker** (multi-stage, Ruby 3.3.2-slim), like method-channel.

## Hosts (see docs/decisions/0006)

- `pinpoint.com` (+ `www`) — landing
- `app.pinpoint.com` — user app
- `admin.pinpoint.com` — admin (consider IP allowlist / separate proxy)

All three are the **same** Rails app; the proxy routes every host to it and Rails splits by
subdomain. Configure SSL for the apex + both subdomains.

## Pre-deploy

- [ ] `RAILS_MASTER_KEY` set (decrypts credentials incl. Aliyun keys).
- [ ] Aliyun credentials populated (`bin/rails credentials:edit`) — see `.env.example` for shape.
- [ ] `APP_DOMAIN` / host config set for the target environment.
- [ ] Postgres reachable; the four databases (primary/cache/queue/cable) exist or are created.
- [ ] Redis reachable (`REDIS_URL`) for Sidekiq.
- [ ] Node ≥22.12 in the build image (Vite 8). `.tool-versions` pins 22.22.3 locally.
- [ ] `bundle exec rspec`, `bin/rubocop`, `bin/brakeman` green in CI.

## Build & ship (Kamal)

- [ ] `config/deploy.yml` updated with real servers, registry, and the three hosts.
- [ ] Assets: `bin/vite build` runs in the image build; `public/vite-*` produced.
- [ ] `kamal deploy`.

## Post-deploy

- [ ] `/up` returns 200 on each host.
- [ ] Aliyun VOD webhook URL (Phase 2) points at the deployed backend and verifies signatures.
- [ ] Background jobs processing (Sidekiq / Solid Queue).

## Kamal aliases (to add in deploy.yml)

`console`, `shell`, `logs`, `dbc` — mirror method-channel.
