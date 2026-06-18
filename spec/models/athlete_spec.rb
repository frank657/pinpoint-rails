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

  describe "avatar fallback (iteration 0007)" do
    around { |ex| ActsAsTenant.with_tenant(workspace, &ex) }

    it "derives up-to-two-letter initials from the name" do
      expect(build(:athlete, name: "John Danaher").initials).to eq("JD")
      expect(build(:athlete, name: "JFLOJUDO").initials).to eq("J")
    end

    it "derives a stable hue in 0..359 from the name" do
      a = build(:athlete, name: "Gordon Ryan")
      expect(a.avatar_hue).to eq(a.avatar_hue).and be_between(0, 359)
    end

    it "is unattached by default (UI uses the initials fallback)" do
      expect(create(:athlete, name: "Lachlan Giles").avatar).not_to be_attached
    end

    # Now that Athlete is uuid-keyed (ADR 0012), the avatar attaches into Active Storage
    # (whose record_id is uuid) without the prior bigint mismatch.
    it "accepts an attached avatar image" do
      athlete = create(:athlete, name: "Gordon Ryan")
      athlete.avatar.attach(io: StringIO.new("img"), filename: "a.png", content_type: "image/png")
      expect(athlete.avatar).to be_attached
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
