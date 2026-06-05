require "rails_helper"

RSpec.describe "Taxonomy (Category & Tag)", type: :model do
  let(:workspace) { create(:user).workspaces.first }
  let(:other_workspace) { create(:user).workspaces.first }

  describe Category do
    it "is unique by name within a workspace (case-insensitive)" do
      ActsAsTenant.with_tenant(workspace) do
        create(:category, name: "Sweeps")
        expect(build(:category, name: "sweeps")).not_to be_valid
      end
    end

    it "allows the same name in a different workspace" do
      ActsAsTenant.with_tenant(workspace) { create(:category, name: "Sweeps") }
      other = ActsAsTenant.with_tenant(other_workspace) { build(:category, name: "Sweeps") }
      expect(other).to be_valid
    end
  end

  describe Tag do
    before { ActsAsTenant.current_tenant = workspace }

    it ".for_names finds-or-creates tags by name, de-duplicating case-insensitively" do
      create(:tag, name: "guard")
      tags = Tag.for_names([ "guard", "GUARD", "sweep", "" ])
      expect(tags.map(&:name)).to contain_exactly("guard", "sweep")
      expect(Tag.count).to eq(2)
    end
  end
end
