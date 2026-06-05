require "rails_helper"

RSpec.describe "Admin access", type: :request do
  before { host! "admin.lvh.me" }

  it "forbids anonymous users" do
    get "/", headers: inertia_headers
    expect(response).to have_http_status(:forbidden)
  end

  it "forbids signed-in non-admins" do
    sign_in create(:user)
    get "/", headers: inertia_headers
    expect(response).to have_http_status(:forbidden)
  end

  it "allows admins" do
    sign_in create(:user, :admin)
    get "/", headers: inertia_headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["component"]).to eq("admin/Dashboard")
  end
end
