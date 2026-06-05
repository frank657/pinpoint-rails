# Routes the three host roles described in docs/decisions/0006:
#   app.<domain>   → the authenticated user product
#   admin.<domain> → the admin panel
#   apex / www     → marketing & landing
#
# Works in development via *.lvh.me (which resolves to 127.0.0.1) and in production via
# the real domain — both use Rails' default tld_length of 1.
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
