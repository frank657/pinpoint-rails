require "rails_helper"

# Each host role (docs/decisions/0006) resolves to its own Inertia page. Uses the
# X-Inertia header so the response is the JSON page object (component + props) rather than
# the full HTML layout — keeping the spec independent of a Vite build.
RSpec.describe "Subdomain routing", type: :request do
  def component(response)
    JSON.parse(response.body)["component"]
  end

  it "serves the landing page on the apex host (no auth)" do
    get "/", headers: inertia_headers.merge("HOST" => "lvh.me")
    expect(response).to have_http_status(:ok)
    expect(component(response)).to eq("Landing")
  end

  it "serves the user dashboard on the app subdomain (authenticated)" do
    sign_in create(:user)
    get "/", headers: inertia_headers.merge("HOST" => "app.lvh.me")
    expect(response).to have_http_status(:ok)
    expect(component(response)).to eq("Dashboard")
  end

  it "serves the admin dashboard on the admin subdomain (admin only)" do
    sign_in create(:user, :admin)
    get "/", headers: inertia_headers.merge("HOST" => "admin.lvh.me")
    expect(response).to have_http_status(:ok)
    expect(component(response)).to eq("admin/Dashboard")
  end
end
