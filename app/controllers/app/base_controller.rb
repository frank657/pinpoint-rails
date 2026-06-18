module App
  # Base controller for the app.<domain> product surface.
  #
  # Enforces authentication, resolves the current Workspace from the session, and scopes
  # the whole request to that tenant (docs/decisions/0002). Every app controller inherits
  # this, so all tenant-scoped queries downstream are automatically workspace-isolated.
  class BaseController < ApplicationController
    include ContentJson

    before_action :authenticate_user!
    before_action :set_current_workspace
    around_action :scope_to_current_tenant

    private

    def set_current_workspace
      @current_workspace = resolve_current_workspace
    end

    def resolve_current_workspace
      workspace = current_user.workspaces.find_by(id: session[:current_workspace_id])
      # Oldest workspace as the default — order explicitly (ids are uuid, so implicit id order is
      # not chronological).
      workspace ||= current_user.workspaces.order(:created_at).first
      session[:current_workspace_id] = workspace&.id
      workspace
    end

    def current_workspace
      @current_workspace
    end
    helper_method :current_workspace

    def scope_to_current_tenant
      ActsAsTenant.with_tenant(current_workspace) { yield }
    end

    inertia_share do
      {
        currentWorkspace: current_workspace && workspace_json(current_workspace),
        workspaces: current_user.workspaces.order(:created_at).map { |w| workspace_json(w) }
      }
    end

    def workspace_json(workspace)
      { id: workspace.id, name: workspace.name, slug: workspace.slug }
    end

    # The current user's progress on a trackable (Axis 3 — per user + workspace).
    def my_progress(trackable)
      Progress.find_by(user: current_user, workspace: current_workspace, trackable: trackable)
    end
  end
end
