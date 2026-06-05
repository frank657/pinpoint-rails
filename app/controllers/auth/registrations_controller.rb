module Auth
  class RegistrationsController < Devise::RegistrationsController
    def new
      render inertia: "auth/SignUp"
    end

    def create
      build_resource(sign_up_params)

      if resource.save
        sign_up(resource_name, resource)
        redirect_to after_sign_up_path_for(resource)
      else
        clean_up_passwords(resource)
        redirect_to new_user_registration_path, inertia: { errors: resource.errors }
      end
    end
  end
end
