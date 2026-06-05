require "rails_helper"

RSpec.describe "Admin panel", type: :request do
  before { host! "admin.lvh.me" }

  let(:admin) { create(:user, :admin) }

  it "forbids non-admins across the whole namespace" do
    sign_in create(:user)
    %w[/ /users /workspaces /videos].each do |path|
      get path, headers: inertia_headers
      expect(response).to have_http_status(:forbidden), "expected 403 for #{path}"
    end
  end

  it "shows cross-tenant stats on the dashboard" do
    create(:user) # another user + workspace
    sign_in admin
    get "/", headers: inertia_headers
    stats = inertia_props(response)["stats"]
    expect(stats["users"]).to be >= 2
    expect(stats["workspaces"]).to be >= 2
  end

  it "lists users and toggles admin" do
    target = create(:user)
    sign_in admin
    get "/users", headers: inertia_headers
    emails = inertia_props(response)["users"].map { |u| u["email"] }
    expect(emails).to include(target.email)

    patch "/users/#{target.id}", params: { admin: true }
    expect(target.reload.admin?).to be(true)
  end
end
