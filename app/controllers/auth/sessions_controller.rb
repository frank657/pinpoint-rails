module Auth
  class SessionsController < Devise::SessionsController
    # On bad credentials Warden re-dispatches (recalls) this action — still a POST, with
    # Devise's i18n reason in flash.now[:alert]. A failed sign-in is a *form submission*
    # error, so we surface it as an Inertia validation error (props[:errors][:base])
    # rather than a flash banner: useForm renders it inline and clears it on resubmit,
    # and the typed email is preserved (recall re-renders the same request). A plain GET
    # — including the "you need to sign in" redirect — keeps the flash banner.
    def new
      if request.post? && flash.now[:alert].present?
        message = flash.now[:alert]
        flash.now[:alert] = nil # don't also show it as a banner
        render inertia: "auth/SignIn", props: { errors: { base: message } }
      else
        render inertia: "auth/SignIn"
      end
    end

    # create / destroy use Devise defaults. create authenticates via Warden; on failure
    # Warden recalls #new (see above). On success it redirects, which Inertia follows.
  end
end
