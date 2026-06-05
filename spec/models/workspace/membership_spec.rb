require "rails_helper"

RSpec.describe Workspace::Membership, type: :model do
  subject { build(:workspace_membership) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:workspace) }
  it { is_expected.to define_enum_for(:role).with_values(owner: 0, member: 1) }

  it "uses the workspace_memberships table" do
    expect(described_class.table_name).to eq("workspace_memberships")
  end

  it "is unique per (user, workspace)" do
    membership = create(:workspace_membership)
    dup = build(:workspace_membership, user: membership.user, workspace: membership.workspace)
    expect(dup).not_to be_valid
  end
end
