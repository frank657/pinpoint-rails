require "rails_helper"

RSpec.describe "Workspaces", type: :request do
  let(:user) { create(:user) }

  before do
    host! "app.lvh.me"
    sign_in user
  end

  describe "current workspace resolution" do
    it "exposes the user's workspace as the current tenant on each request" do
      get app_root_path, headers: inertia_headers
      props = inertia_props(response)
      expect(props["currentWorkspace"]["id"]).to eq(user.workspaces.first.id)
    end

    it "leaves no tenant set outside the request" do
      get app_root_path, headers: inertia_headers
      expect(ActsAsTenant.current_tenant).to be_nil
    end

    # Regression (ADR 0012): with uuid PKs, `workspaces.first` no longer means "oldest" — the
    # default must order by created_at, not by the (now random) uuid id.
    it "defaults to the oldest workspace, not an arbitrary uuid order" do
      oldest = user.workspaces.order(:created_at).first
      Workspace::Membership.create!(user: user, workspace: Workspace.create!(name: "Newer"))
      get app_root_path, headers: inertia_headers
      expect(inertia_props(response)["currentWorkspace"]["id"]).to eq(oldest.id)
    end
  end

  describe "creating and switching workspaces" do
    it "creates a workspace and makes it current" do
      expect {
        post app_workspaces_path, params: { name: "BJJ" }
      }.to change { user.reload.workspaces.count }.by(1)

      get app_root_path, headers: inertia_headers
      expect(inertia_props(response)["currentWorkspace"]["name"]).to eq("BJJ")
    end

    it "switches between the user's workspaces and persists the choice" do
      post app_workspaces_path, params: { name: "Guitar" }
      first = user.workspaces.order(:created_at).first

      post app_switch_workspace_path(first)
      get app_root_path, headers: inertia_headers
      expect(inertia_props(response)["currentWorkspace"]["id"]).to eq(first.id)
    end
  end

  describe "cross-workspace access" do
    it "forbids switching to a workspace the user does not belong to" do
      other = create(:user).workspaces.first
      post app_switch_workspace_path(other)
      expect(response).to have_http_status(:forbidden)
    end

    it "forbids renaming a workspace the user does not belong to" do
      other = create(:user).workspaces.first
      patch app_workspace_path(other), params: { name: "hacked" }
      expect(response).to have_http_status(:forbidden)
      expect(other.reload.name).not_to eq("hacked")
    end
  end

  describe "keeping at least one workspace" do
    it "refuses to delete the user's only workspace" do
      only = user.workspaces.first
      delete app_workspace_path(only)
      expect(user.reload.workspaces).to include(only)
    end
  end
end
