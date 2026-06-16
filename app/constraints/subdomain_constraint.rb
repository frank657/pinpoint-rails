# Routes the three host roles described in docs/decisions/0006:
#   app.<domain>   → the authenticated user product
#   admin.<domain> → the admin panel
#   apex / www     → marketing & landing
#
# Works in development via *.lvh.me (resolves to 127.0.0.1) and in production via the real
# domain. The subdomain Rails extracts depends on `config.action_dispatch.tld_length`, which
# must match the base domain's label count: lvh.me / pinpoint.com (2 labels) ⇒ 1, while
# pinpoint.brainchild.cloud (3 labels) ⇒ 2. Production derives it from APP_DOMAIN — see
# config/environments/production.rb.
class SubdomainConstraint
  def self.app   = new("app")
  def self.admin = new("admin")
  def self.apex  = new("", "www")

  def initialize(*subdomains)
    @subdomains = subdomains.map(&:to_s)
  end

  def matches?(request)
    @subdomains.include?(request.subdomain.to_s)
  end
end
