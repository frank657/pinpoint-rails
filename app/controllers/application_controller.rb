class ApplicationController < ActionController::Base
  include ActionPolicy::Controller

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # The signed-in User is the authorization context for all policies (docs/decisions/0008).
  authorize :user, through: :current_user

  # Expose the CSRF token to the Inertia/axios client as a cross-subdomain cookie. The
  # client (see app/frontend/entrypoints/inertia.tsx) sends it back as the X-CSRF-Token
  # header, which Rails verifies. Cookie spans subdomains to match the session (ADR 0006).
  after_action :set_csrf_cookie

  # Authorization failures become 403s rather than 500s.
  rescue_from ActionPolicy::Unauthorized do
    head :forbidden
  end

  # A stale/invalid CSRF token (an old tab, or after the dev server restarts) otherwise
  # makes a form POST fail with a silent 422 — the submit appears to do nothing. Redirect
  # back instead: the redirect refreshes the XSRF-TOKEN cookie (set_csrf_cookie) and
  # surfaces a recoverable flash, so the retry succeeds.
  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_back fallback_location: "/", alert: "Your session expired — please try again."
  end

  # Data shared with every Inertia response across all subdomains.
  inertia_share do
    {
      flash: { notice: flash.notice, alert: flash.alert },
      currentUser: current_user && {
        id: current_user.id,
        email: current_user.email,
        admin: current_user.admin?
      }
    }
  end

  private

  def set_csrf_cookie
    cookies["XSRF-TOKEN"] = {
      value: form_authenticity_token,
      domain: :all,
      same_site: :lax
    }
  end
end
