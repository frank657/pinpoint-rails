# Multi-tenancy scoped to Workspace (docs/decisions/0002).
#
# require_tenant = true makes any query on an acts_as_tenant model raise when no current
# tenant is set — catching tenancy misconfiguration early. Contexts that legitimately run
# without a request (background jobs, Aliyun VOD webhooks, the admin panel) must set the
# tenant explicitly via `ActsAsTenant.with_tenant` / `without_tenant`.
ActsAsTenant.configure do |config|
  config.require_tenant = true
end
