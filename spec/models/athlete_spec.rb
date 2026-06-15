require "rails_helper"

RSpec.describe Athlete, type: :model do
  let(:workspace) { create(:user).workspaces.first }
  let(:other_workspace) { create(:user).workspaces.first }

  it "is unique by name within a workspace (case-insensitive)" do
    ActsAsTenant.with_tenant(workspace) do
      create(:athlete, name: "John Danaher")
      expect(build(:athlete, name: "john danaher")).not_to be_valid
    end
  end

  it "allows the same name in a different workspace" do
    ActsAsTenant.with_tenant(workspace) { create(:athlete, name: "John Danaher") }
    other = ActsAsTenant.with_tenant(other_workspace) { build(:athlete, name: "John Danaher") }
    expect(other).to be_valid
  end

  describe ".for_names" do
    before { ActsAsTenant.current_tenant = workspace }

    it "finds-or-creates by name, de-duplicating case-insensitively" do
      create(:athlete, name: "Gordon Ryan")
      athletes = Athlete.for_names([ "Gordon Ryan", "gordon ryan", "Lachlan Giles", "" ])
      expect(athletes.map(&:name)).to contain_exactly("Gordon Ryan", "Lachlan Giles")
      expect(Athlete.count).to eq(2)
    end
  end

  describe "many-to-many with Video" do
    around { |ex| ActsAsTenant.with_tenant(workspace, &ex) }

    it "associates athletes and videos both directions" do
      video = create(:video, workspace: workspace)
      athlete = create(:athlete, name: "Mikey Musumeci")

      video.athletes << athlete

      expect(video.reload.athletes).to include(athlete)
      expect(athlete.reload.videos).to include(video)
    end

    it "scopes athletes to the current workspace" do
      create(:athlete, name: "Local")
      ActsAsTenant.with_tenant(other_workspace) { create(:athlete, name: "Elsewhere") }
      expect(Athlete.pluck(:name)).to eq([ "Local" ])
    end
  end
end
