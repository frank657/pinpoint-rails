module Auth
  class PasswordsController < Devise::PasswordsController
    def new
      render inertia: "auth/ForgotPassword"
    end

    def edit
      render inertia: "auth/ResetPassword", props: {
        resetPasswordToken: params[:reset_password_token]
      }
    end

    def create
      self.resource = resource_class.send_reset_password_instructions(resource_params)

      if successfully_sent?(resource)
        redirect_to new_user_session_path
      else
        redirect_to new_user_password_path, inertia: { errors: resource.errors }
      end
    end

    def update
      self.resource = resource_class.reset_password_by_token(resource_params)

      if resource.errors.empty?
        flash[:notice] = "Your password has been reset. Please sign in."
        redirect_to new_user_session_path
      else
        redirect_to(
          edit_user_password_path(reset_password_token: resource_params[:reset_password_token]),
          inertia: { errors: resource.errors }
        )
      end
    end
  end
end
