require "rails_helper"

RSpec.describe Workspace, type: :model do
  it { is_expected.to have_many(:workspace_memberships).dependent(:destroy) }
  it { is_expected.to have_many(:members).through(:workspace_memberships) }
  it { is_expected.to validate_presence_of(:name) }

  it "generates a unique slug even when names collide" do
    a = Workspace.create!(name: "Personal")
    b = Workspace.create!(name: "Personal")
    expect(a.slug).to eq("personal")
    expect(b.slug).not_to eq(a.slug)
  end

  describe "#owner" do
    it "returns the user with the owner membership" do
      user = create(:user)
      expect(user.workspaces.first.owner).to eq(user)
    end
  end
end
