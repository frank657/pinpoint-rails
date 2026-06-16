# Central app configuration — single source of truth for environment + the three
# subdomain hosts (docs/decisions/0006). The Aliyun VOD webhook callback URL (Phase 2)
# is derived from here.
module AppConfig
  class << self
    def credentials = Rails.application.credentials

    # Allows overriding the logical environment independently of RAILS_ENV (e.g. a
    # staging build running with RAILS_ENV=production).
    def env = (ENV["APP_ENV"].presence || Rails.env).to_sym

    def production?  = env == :production
    def staging?     = env == :staging
    def development? = env == :development
    def test?        = env == :test

    # Base domain (no subdomain). Dev uses *.lvh.me so subdomain routing works locally.
    def domain
      ENV["APP_DOMAIN"].presence || credentials.dig(:host, :domain) || "lvh.me:3000"
    end

    def protocol = (production? || staging?) ? "https" : "http"

    def host_landing = build_host(nil)
    def host_app     = build_host("app")
    def host_admin   = build_host("admin")

    # Backend URL used for outbound webhook callbacks (Aliyun VOD, Phase 2). Read from
    # credentials (host.backend.<env>) so the callback can reach a tunnelled dev host
    # (e.g. cloudflared) — falling back to an env override, then the app host.
    def host_backend
      ENV["APP_BACKEND_URL"].presence ||
        credentials.dig(:host, :backend, env) ||
        host_app
    end

    private

    def build_host(subdomain)
      host = [ subdomain, domain ].compact.join(".")
      "#{protocol}://#{host}"
    end
  end
end
