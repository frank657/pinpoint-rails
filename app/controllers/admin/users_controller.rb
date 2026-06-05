module Admin
  class UsersController < BaseController
    def index
      users = User.order(created_at: :desc)
      users = users.where("email ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      render inertia: "admin/Users", props: {
        users: users.limit(100).map { |u|
          { id: u.id, email: u.email, admin: u.admin?, workspaceCount: u.workspaces.count, createdAt: u.created_at.iso8601 }
        },
        q: params[:q]
      }
    end

    def update
      user = User.find(params[:id])
      user.update!(admin: ActiveModel::Type::Boolean.new.cast(params[:admin]))
      redirect_back fallback_location: admin_users_path
    end
  end
end
