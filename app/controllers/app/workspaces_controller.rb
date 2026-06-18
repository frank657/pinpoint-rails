module App
  class WorkspacesController < BaseController
    def index
      render inertia: "workspaces/Index", props: {
        workspaces: current_user.workspaces.order(:created_at).map { |w| workspace_json(w) }
      }
    end

    def create
      workspace = Workspace.new(name: params[:name].presence || "Untitled workspace")
      workspace.save!
      current_user.workspace_memberships.create!(workspace: workspace, role: :owner)
      session[:current_workspace_id] = workspace.id
      redirect_to app_root_path, notice: "Workspace created."
    end

    def update
      workspace = Workspace.friendly.find(params[:id])
      authorize! workspace, to: :update?
      workspace.update!(name: params[:name])
      redirect_back fallback_location: app_workspaces_path, notice: "Workspace renamed."
    end

    def destroy
      workspace = Workspace.friendly.find(params[:id])
      authorize! workspace, to: :destroy?

      if current_user.workspaces.count <= 1
        redirect_back fallback_location: app_workspaces_path,
                      alert: "You must keep at least one workspace."
        return
      end

      workspace.destroy!
      session[:current_workspace_id] = current_user.workspaces.order(:created_at).first&.id
      redirect_to app_root_path, notice: "Workspace deleted."
    end

    def switch
      workspace = Workspace.friendly.find(params[:id])
      authorize! workspace, to: :manage?
      session[:current_workspace_id] = workspace.id
      redirect_to app_root_path
    end
  end
end
