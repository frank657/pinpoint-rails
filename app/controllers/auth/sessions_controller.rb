module Auth
  class SessionsController < Devise::SessionsController
    def new
      render inertia: "auth/SignIn"
    end

    # create / destroy use Devise defaults (redirects, which Inertia follows). On bad
    # credentials, Warden's failure app redirects back to sign-in with a flash alert,
    # surfaced via the shared flash (ApplicationController).
  end
end
