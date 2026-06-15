require "rails_helper"

RSpec.describe "Tags management", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  describe "GET /tags" do
    it "renders the management page with names and usage counts, tenant-scoped" do
      guard = create(:tag, workspace: workspace, name: "guard")
      create(:note).tap { |n| n.tags = [ guard ] }
      create(:tag, workspace: workspace, name: "mount")

      # A tag in another workspace must not leak in.
      other_ws = create(:user).workspaces.first
      ActsAsTenant.with_tenant(other_ws) { create(:tag, workspace: other_ws, name: "elsewhere") }

      get app_tags_path, headers: inertia_headers
      tags = inertia_props(response).fetch("tags")

      expect(tags.map { |t| t["name"] }).to contain_exactly("guard", "mount")
      expect(tags.find { |t| t["name"] == "guard" }["count"]).to eq(1)
    end
  end

  describe "POST /tags" do
    it "creates a tag" do
      expect { post app_tags_path, params: { name: "berimbolo" } }.to change(Tag, :count).by(1)
      expect(Tag.last.name).to eq("berimbolo")
    end
  end

  describe "PATCH /tags/:id" do
    it "renames a tag" do
      tag = create(:tag, workspace: workspace, name: "old")
      patch app_tag_path(tag), params: { name: "new" }
      expect(tag.reload.name).to eq("new")
    end
  end

  describe "DELETE /tags/:id" do
    it "deletes a tag and its taggings" do
      tag = create(:tag, workspace: workspace, name: "doomed")
      create(:note).tags = [ tag ]
      expect { delete app_tag_path(tag) }.to change(Tag, :count).by(-1)
      expect(Tagging.where(tag_id: tag.id)).to be_empty
    end
  end

  describe "POST /tags/:id/merge" do
    it "merges the source tag into the target" do
      source = create(:tag, workspace: workspace, name: "bjj")
      target = create(:tag, workspace: workspace, name: "jiujitsu")
      note = create(:note)
      note.tags = [ source ]

      post merge_app_tag_path(source), params: { target_id: target.id }

      expect(Tag.exists?(source.id)).to be(false)
      expect(note.reload.tags).to contain_exactly(target)
    end
  end

  describe "tagging still works elsewhere" do
    it "creates a note with tags and filters the index by tag" do
      video = create(:video, workspace: workspace)
      post app_notes_path, params: {
        note_type: "timestamp", video_id: video.id, start_seconds: "5",
        title: "Grip", tag_names: [ "guard" ]
      }
      expect(Note.last.tags.map(&:name)).to contain_exactly("guard")

      get app_notes_path, params: { tag: "guard" }, headers: inertia_headers
      notes = inertia_props(response).fetch("notes")
      expect(notes.map { |n| n["title"] }).to include("Grip")

      get app_notes_path, params: { tag: "nonexistent" }, headers: inertia_headers
      expect(inertia_props(response).fetch("notes")).to be_empty
    end

    it "exposes video tags on the video show page" do
      video = create(:video, workspace: workspace)
      video.tag_names = [ "highlight" ]
      get app_video_path(video), headers: inertia_headers
      expect(inertia_props(response).dig("video", "tags")).to contain_exactly("highlight")
    end
  end
end
