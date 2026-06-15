# frozen_string_literal: true

# Devise's default FailureApp returns a bare 401 for XHR requests, because
# Devise.http_authenticatable_on_xhr is true (see config/initializers/devise.rb).
#
# Inertia visits are XHRs (axios sends X-Requested-With + X-Inertia). So an
# unauthenticated visit to a protected page — or a failed sign-in — would get a
# 401 HTML body that the Inertia client cannot parse as an Inertia response. It
# falls back to dumping the raw HTML into its full-screen error modal (the white
# box showing the Devise "You need to sign in…" flash).
#
# For Inertia requests we skip HTTP-auth and fall through to Devise's normal
# redirect (unauthenticated) / recall (bad credentials) behaviour:
#   * redirect → 302 to /users/sign_in. The Inertia client follows it; the
#     follow-up GET (carrying X-Inertia) returns 409 + X-Inertia-Location, which
#     triggers a clean full page load of the styled sign-in page with the flash.
#   * recall → re-dispatches to Auth::SessionsController#new, a normal Inertia
#     render of the sign-in page with the "Invalid email or password" flash.
#
# See docs/decisions/0001 (session-based Devise auth behind Inertia).
class InertiaFailureApp < Devise::FailureApp
  def http_auth?
    return false if inertia_request?

    super
  end

  private

  def inertia_request?
    request.get_header("HTTP_X_INERTIA").present?
  end
end
