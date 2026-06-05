require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to have_many(:workspace_memberships).dependent(:destroy) }
  it { is_expected.to have_many(:workspaces).through(:workspace_memberships) }

  describe "on creation" do
    let(:user) { create(:user) }

    it "creates a default 'Personal' workspace owned by the user" do
      expect(user.workspaces.pluck(:name)).to eq([ "Personal" ])
      expect(user.workspace_memberships.first.role).to eq("owner")
    end
  end

  describe "#member_of?" do
    let(:user) { create(:user) }

    it "is true for a workspace the user belongs to" do
      expect(user.member_of?(user.workspaces.first)).to be(true)
    end

    it "is false for a workspace the user does not belong to" do
      other = create(:user).workspaces.first
      expect(user.member_of?(other)).to be(false)
    end
  end

  it "defaults admin to false" do
    expect(create(:user).admin?).to be(false)
  end
end
