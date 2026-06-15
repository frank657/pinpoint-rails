require "rails_helper"

RSpec.describe Tag, type: :model do
  let(:workspace) { create(:user).workspaces.first }
  before { ActsAsTenant.current_tenant = workspace }

  describe "validations" do
    it "is unique per workspace, case-insensitively" do
      create(:tag, name: "Guard")
      expect(build(:tag, name: "guard")).not_to be_valid
    end
  end

  describe ".for_names" do
    it "find-or-creates by name, de-duping case-insensitively" do
      existing = create(:tag, name: "guard")
      tags = Tag.for_names([ "Guard", " mount ", "mount", "" ])
      expect(tags.map(&:name)).to contain_exactly("guard", "mount")
      expect(tags).to include(existing)
    end
  end

  describe "polymorphic tagging across content types" do
    it "applies the same tag to a Note and a Video" do
      tag = create(:tag, name: "sweep")
      note = create(:note)
      video = create(:video, workspace: workspace)

      note.tags = [ tag ]
      video.tags = [ tag ]

      expect(note.reload.tags).to contain_exactly(tag)
      expect(video.reload.tags).to contain_exactly(tag)
      expect(tag.usage_count).to eq(2)
    end

    it "tags a Video by name via the Taggable setter" do
      video = create(:video, workspace: workspace)
      video.tag_names = [ "guard", "guard", "pass" ]
      expect(video.reload.tag_names).to contain_exactly("guard", "pass")
    end

    it "scopes taggings to the workspace and forbids duplicates" do
      tag = create(:tag, name: "x")
      note = create(:note)
      note.tags = [ tag ]
      tagging = Tagging.last
      expect(tagging.workspace).to eq(workspace)
      dup = Tagging.new(tag: tag, taggable_type: "Note", taggable_id: note.id)
      expect(dup).not_to be_valid
    end
  end

  describe "#merge_into!" do
    it "re-points taggings onto the target, de-dups, and deletes the source" do
      source = create(:tag, name: "bjj")
      target = create(:tag, name: "jiujitsu")
      shared = create(:note)
      only_source = create(:video, workspace: workspace)

      shared.tags = [ source, target ] # both already point at `shared`
      only_source.tags = [ source ]

      result = source.merge_into!(target)

      expect(result).to eq(target)
      expect(Tag.exists?(source.id)).to be(false)
      expect(shared.reload.tags).to contain_exactly(target)        # de-duped, not doubled
      expect(only_source.reload.tags).to contain_exactly(target)   # moved over
    end

    it "is a no-op when merging into itself" do
      tag = create(:tag, name: "solo")
      expect { tag.merge_into!(tag) }.not_to change(Tag, :count)
    end
  end
end
