module Admin
  # Base controller for the admin.<domain> panel.
  #
  # Defense in depth (docs/decisions/0006): the admin subdomain is only a routing
  # convenience — every action requires an authenticated admin. Admin operates ACROSS
  # workspaces, so actions run without a tenant (ActsAsTenant.without_tenant).
  class BaseController < ApplicationController
    before_action :require_admin
    around_action :run_without_tenant

    private

    def require_admin
      head :forbidden unless current_user&.admin?
    end

    def run_without_tenant(&)
      ActsAsTenant.without_tenant(&)
    end
  end
end
