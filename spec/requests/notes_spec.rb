require "rails_helper"

RSpec.describe "Notes", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }
  let(:video) { create(:video, workspace: workspace) }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  describe "POST /notes (timestamp note on a video)" do
    it "creates a point note capturing numeric seconds, with category and tags" do
      category = create(:category, workspace: workspace, name: "Sweeps")

      expect {
        post app_notes_path, params: {
          note_type: "timestamp", video_id: video.id, start_seconds: "42.5",
          title: "Grip first", category_id: category.id, tag_names: [ "guard", "closed" ]
        }
      }.to change(Note, :count).by(1)

      note = Note.last
      expect(note.start_seconds).to eq(42.5)
      expect(note.category).to eq(category)
      expect(note.tags.map(&:name)).to contain_exactly("guard", "closed")
      expect(response).to redirect_to(app_video_path(video))
    end

    it "creates a range note" do
      post app_notes_path, params: {
        note_type: "timestamp", video_id: video.id, start_seconds: "10", end_seconds: "25", title: "Drill"
      }
      expect(Note.last).to be_range
    end
  end

  describe "POST /notes (standalone rich_text note)" do
    it "creates a rich-text note with an Action Text body" do
      post app_notes_path, params: {
        note_type: "rich_text", title: "Game plan", body: "<div>Pass then <em>mount</em></div>"
      }
      note = Note.last
      expect(note).to be_rich_text
      expect(note.body.to_plain_text).to include("Pass then mount")
      expect(response).to redirect_to(app_notes_path)
    end
  end

  describe "GET /notes with filters" do
    it "filters by tag and full-text query" do
      a = create(:note, workspace: workspace, video: video, title: "Closed guard sweep")
      create(:note, workspace: workspace, video: video, title: "Mount escape")
      ActsAsTenant.with_tenant(workspace) { a.tags = Tag.for_names([ "guard" ]); a.save! }

      get app_notes_path(q: "guard"), headers: inertia_headers
      titles = inertia_props(response)["notes"].map { |n| n["title"] }
      expect(titles).to include("Closed guard sweep")
      expect(titles).not_to include("Mount escape")
    end
  end

  describe "PATCH/DELETE /notes/:id" do
    it "updates and deletes a note" do
      note = create(:note, workspace: workspace, video: video, title: "Old")
      patch app_note_path(note), params: { title: "New" }
      expect(note.reload.title).to eq("New")

      expect { delete app_note_path(note) }.to change(Note, :count).by(-1)
    end

    it "forbids editing a note in another workspace" do
      other_ws = create(:user).workspaces.first
      other_note = ActsAsTenant.with_tenant(other_ws) do
        create(:note, workspace: other_ws, video: create(:video, workspace: other_ws))
      end
      # The note isn't visible under the current tenant -> 404 (tenant isolation).
      patch app_note_path(other_note), params: { title: "x" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
