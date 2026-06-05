# Share the session cookie across all subdomains (apex / app / admin) so a single Devise
# login works everywhere — see docs/decisions/0006. `:all` derives the registered domain
# (e.g. ".lvh.me" in dev, ".pinpoint.com" in prod) from the request host.
Rails.application.config.session_store :cookie_store,
  key: "_pinpoint_session",
  domain: :all,
  same_site: :lax
