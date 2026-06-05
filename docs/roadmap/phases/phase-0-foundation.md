# Phase 0 — Foundation & scaffold

**Goal:** turn the fresh `rails new` app into the Pinpoint skeleton: Inertia/React/Vite
frontend, the full gem set, multi-database, subdomain routing shells, RSpec, CI, and a
base controller layer — so every later phase has a place to plug in.

**Depends on:** — · **Locked by:** ADR 0001 (monolith/Inertia), 0006 (subdomains),
0007 (port list)

## Scope

### Gems
- Add (per ADR 0007): `inertia_rails`, `vite_rails`, `tailwindcss-rails` (or Tailwind via
  Vite), `devise`, `action_policy`, `acts_as_tenant`, `sidekiq`, `sidekiq-cron`,
  `friendly_id`, `pg_search`, `kaminari`, `noticed`, `paper_trail` +
  `paper_trail-association_tracking`, `mobility`, `image_processing`, `ruby-vips`,
  `activestorage-aliyun`, `aliyun-sdk`, `aliyunsdkcore`, `nilify_blanks`.
- Dev/test: `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`, `faker`,
  `dotenv-rails`, `pry-rails`, `pry-byebug`, `prosopite`, `awesome_print`, `letter_opener`,
  `brakeman`, `rubocop-rails-omakase`, `capybara`, `selenium-webdriver`.
- Confirm **dropped**: no `devise-jwt`, `active_model_serializers`, `rswag*`, `rack-cors`.

### Frontend
- Inertia + React + Vite wired (`bin/vite`, `app/frontend/`), a root layout, a "Hello"
  Inertia page rendering through a controller, Tailwind compiling.
- `bin/dev` / `Procfile.dev` runs Rails + Vite together.

### Database
- Postgres multi-database (primary/queue/cache/cable) like method-channel; `database.yml`
  for dev (`pinpoint_development`), test (`pinpoint_test`), and `DATABASE_URL` for
  staging/prod. Solid Queue/Cache/Cable installed.

### Routing & controllers
- `config/routes.rb` + `config/routes/` split by **subdomain constraint** (ADR 0006): a
  `Subdomain` constraint class; `app.` routes, `admin.` routes, apex/landing routes.
- Local dev via `*.lvh.me`.
- Base controllers: `ApplicationController` (global rescue, current-user), an
  `App::BaseController` and `Admin::BaseController` shell (auth hooks come in Phases 1/6).
- Inertia shared data (e.g. `current_user`, flash) configured.

### Config / ops
- Aliyun credentials structure in `config/credentials` (encrypted) + `config/storage.yml`
  with the Aliyun service + the `activestorage_aliyun_patch.rb` initializer (ported,
  ADR 0007). No live keys committed; document required keys in `.env.example`.
- `config/initializers/app_config.rb` (host/subdomain helpers), Sidekiq initializer.
- RSpec installed; `spec/rails_helper.rb`, FactoryBot, shoulda-matchers configured.
- CI (GitHub Actions): boot, rubocop, brakeman, rspec.
- `docs/DEPLOY_CHECKLIST.md` + Kamal `config/deploy.yml` adapted for the three subdomains
  (can be a skeleton; real deploy later).

## Key tasks
1. Gemfile changes + `bundle`.
2. `rails g inertia:install` (or manual) + Vite + React + Tailwind; sample page.
3. Multi-DB config + Solid* install + migrate.
4. Subdomain constraint + split routes + base controllers + Inertia shared data.
5. RSpec + FactoryBot + CI green on a trivial spec.
6. Port `storage.yml` + Aliyun AS patch + credentials scaffolding (no live upload yet).

## Out of scope
- Any real auth (Phase 1), any domain models (Video/Note/etc.), real Aliyun upload (Phase 2).

## Exit criteria
- `bin/dev` boots; `app.lvh.me:3000` renders an Inertia/React page through a controller;
  `admin.lvh.me:3000` and the apex resolve to their own route sets.
- `bundle exec rspec` runs green; rubocop + brakeman pass in CI.
- Multi-DB migrates cleanly; Sidekiq boots.
- ADR 0007's "drop" list is honored (no JWT/AMS/rswag/CORS in the bundle).
