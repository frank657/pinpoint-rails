# Testing Guide

How we test Pinpoint. The rule is simple: **every feature ships with tests, and the suite is
green before an iteration is done** (see `iteration-guide.md`). This guide says _what_ to test,
_where_, and _how_ — grounded in the tools already wired up in this repo.

## TL;DR — what to write for what you're building

Pick by the kind of thing you're adding. Most features touch two or three rows.

| You're adding… | Write these (in TDD order) | Lives in |
|---|---|---|
| A model / column / validation / scope / callback | **Model spec** — validations (shoulda-matchers), associations, scopes, tenancy, business methods | `spec/models/` |
| An authorization rule | **Policy spec** — each rule × {owner, workspace member, outsider, admin} | `spec/policies/` |
| A controller action / Inertia page | **Request spec** — component + props, auth gate, authorization, tenant scoping, flash/errors, redirects | `spec/requests/` |
| A domain operation across models | **Service spec** — happy path + the invariants it must keep | `spec/services/` |
| A background job | **Job spec** — enqueues + performs, external providers stubbed | `spec/jobs/` |
| A user-visible journey (multi-step, needs JS) | **System spec** (Capybara) — drives a real browser end-to-end | `spec/system/` |
| Non-trivial client-only logic (reducer, parsing, timestamp math) | **Frontend unit** (optional, add Vitest) — only when isolated & complex | `app/frontend/**/*.test.ts(x)` |

**Always-on gate** (every iteration, no exceptions):

```bash
bundle exec rspec        # all specs green
npm run check            # tsc -p tsconfig.app.json && tsconfig.node.json — types clean
bin/vite build           # production bundle builds
bundle exec rubocop      # lint clean
```

## The shape of the pyramid for this stack

Pinpoint is a Rails monolith with an Inertia/React frontend, `acts_as_tenant` multi-tenancy,
Action Policy authorization, and Devise auth. That shapes where coverage pays off:

- **Request specs are the workhorse.** They exercise routing, tenancy, authorization, the
  controller, and the Inertia payload (component + props) in one cheap test. Lean on these.
- **Model / policy / service specs** cover the logic underneath, fast and in isolation.
- **System specs** cover the **Inertia ↔ React seam** that request specs *cannot* see — form
  submits, redirects-followed-by-the-client, flash rendering, the page actually mounting.
  Every bug in the auth saga (blank page, the white error modal, the silent CSRF 422) lived
  in that seam and was invisible to request specs. Reserve system specs for **critical
  journeys**, not every page.
- **Frontend units** are a last resort for genuinely complex client logic; types + system
  specs cover most of it.

> Rough budget per feature: a handful of model/request specs always; a policy spec whenever
> there's a rule; one system spec per critical journey. Don't chase coverage numbers — cover
> behavior and the failure modes you'd be embarrassed to ship broken.

## Conventions (already set up — use them)

These are configured in `spec/rails_helper.rb` and `spec/support/`.

- **Subdomain.** Routes are split by subdomain (ADR 0006). Set the host in request/system specs:
  `host! "app.lvh.me"` (user app), `"admin.lvh.me"` (admin), or the apex for landing.
- **Auth.** `sign_in(user)` / `sign_out(user)` — `Devise::Test::IntegrationHelpers` (request specs).
- **Tenancy.** `acts_as_tenant` uses a thread-global tenant, reset after every example
  (`spec/support/tenancy.rb`). In request specs that go through a controller the tenant is set
  for you; when you touch tenant-scoped models directly, wrap them:
  `ActsAsTenant.with_tenant(workspace) { ... }` (or set `ActsAsTenant.current_tenant = workspace`).
- **Factories.** FactoryBot, methods included globally (`create(:user)`, `build(:note)`, …).
  Factories live in `spec/factories/`.
- **Model matchers.** shoulda-matchers (`it { is_expected.to validate_presence_of(:title) }`).
- **Never hit the network.** Aliyun VOD/OSS is stubbed in `spec/support/aliyun.rb`; stub any
  future external provider the same way. A spec that makes a real HTTP call is a bug.

### Asserting Inertia responses (request specs)

Inertia actions render a JSON page object (`component` + `props`) when the request carries the
Inertia headers. Use the helpers in `spec/support/request_helpers.rb`:

```ruby
it "renders the dashboard with the due count" do
  get app_root_path, headers: inertia_headers
  expect(response).to have_http_status(:ok)
  props = inertia_props(response)            # => parsed props hash
  expect(props["dueCount"]).to eq(3)
end
```

For a plain form POST (no Inertia headers needed) assert the redirect/flash as usual:
`expect(response).to redirect_to(app_root_path)`.

**Test Inertia actions as Inertia requests.** A request without `X-Inertia` takes a different
branch than the real client (this is exactly how the auth-failure 401 modal bug hid). When the
behavior depends on it being an XHR (auth failures, redirects), send `inertia_headers`.

### A representative request spec

```ruby
RSpec.describe "Notes", type: :request do
  let(:user)      { create(:user) }
  let(:workspace) { user.workspaces.first }
  let(:video)     { create(:video, workspace:) }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  it "creates a point note capturing numeric seconds" do
    expect {
      post app_notes_path, params: { note_type: "timestamp", video_id: video.id, start_seconds: "42.5" }
    }.to change(Note, :count).by(1)
    expect(Note.last.start_seconds).to eq(42.5)
    expect(response).to redirect_to(app_video_path(video))
  end

  it "denies access to another workspace's video" do
    other = create(:video)  # different workspace
    post app_notes_path, params: { note_type: "timestamp", video_id: other.id, start_seconds: "1" }
    expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
  end
end
```

Note the second example: **tenancy and authorization are part of the feature**, so they're part
of the test. For anything workspace-owned, prove an outsider can't reach it.

## System specs (browser, end-to-end)

Capybara + `selenium-webdriver` are already in the Gemfile; there are no system specs yet.
The first one to add wires the harness (headless Chrome) — see `iteration-guide.md` for the
suggested setup. Use system specs for the few journeys whose correctness lives in the browser:

- **Auth** — sign up, sign in (good & bad password), sign out, protected-route redirect.
- **Take a note on a video** — the core loop.
- **Share / fork** — the cross-workspace flow.

Keep them few and high-signal; they're slower and more brittle than request specs.

## What to add next (current gaps)

The suite covers models, policies, requests, services, jobs — but two gaps caused real bugs:

1. **No system specs.** The Inertia/React seam is untested. Add `spec/system/auth_spec.rb`
   first (it also stands up the Capybara harness for everything after).
2. **Auth edge cases under Inertia/CSRF aren't asserted.** Add request specs that (a) send
   `inertia_headers` and assert an unauthenticated XHR **redirects** (not 401), (b) assert a
   bad-password response carries `errors.base` in props, (c) exercise the CSRF rescue with
   `ActionController::Base.allow_forgery_protection = true` around the example.

These are the regression tests for the auth work in iterations to date; fold them into the next
auth-touching iteration.
