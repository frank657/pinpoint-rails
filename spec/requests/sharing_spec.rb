require "rails_helper"

RSpec.describe "Sharing & forking", type: :request do
  let(:owner) { create(:user) }
  let(:owner_ws) { owner.workspaces.first }
  let(:recipient) { create(:user) }
  let(:recipient_ws) { recipient.workspaces.first }

  let!(:notebook) { ActsAsTenant.with_tenant(owner_ws) { create(:notebook, workspace: owner_ws, title: "Back Attacks") } }

  before { host! "app.lvh.me" }

  it "lets the owner create a share link" do
    sign_in owner
    ActsAsTenant.current_tenant = owner_ws
    expect {
      post app_shares_path, params: { shareable_type: "Notebook", shareable_id: notebook.id }
    }.to change(Share, :count).by(1)
    expect(Share.last.token).to be_present
  end

  it "lets a recipient in another workspace view and fork the share" do
    token = ActsAsTenant.with_tenant(owner_ws) { Share.create!(shareable: notebook, shared_by: owner).token }

    sign_in recipient
    # view
    get app_share_view_path(token), headers: inertia_headers.merge("HOST" => "app.lvh.me")
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["props"]["content"]["title"]).to eq("Back Attacks")

    # fork into the recipient's workspace
    expect {
      post app_share_fork_path(token)
    }.to change { ActsAsTenant.with_tenant(recipient_ws) { Notebook.count } }.by(1)

    forked = ActsAsTenant.with_tenant(recipient_ws) { Notebook.find_by(title: "Back Attacks") }
    expect(forked).to be_present
    expect(forked.workspace).to eq(recipient_ws)
    expect(response).to redirect_to(app_notebook_path(forked))
  end
end
