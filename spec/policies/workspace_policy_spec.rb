require "rails_helper"

RSpec.describe WorkspacePolicy do
  let(:user) { create(:user) }
  let(:own_workspace) { user.workspaces.first }
  let(:other_workspace) { create(:user).workspaces.first }

  def policy_for(record)
    described_class.new(record, user: user)
  end

  it "permits a member to manage their workspace" do
    expect(policy_for(own_workspace).apply(:manage?)).to be(true)
  end

  it "denies managing a workspace the user does not belong to" do
    expect(policy_for(other_workspace).apply(:manage?)).to be(false)
  end

  it "aliases show?/update?/destroy? to manage?" do
    policy = policy_for(own_workspace)
    expect(policy.apply(:update?)).to be(true)
    expect(policy.apply(:destroy?)).to be(true)
    expect(policy.apply(:show?)).to be(true)
  end
end
