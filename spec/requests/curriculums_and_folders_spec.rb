require "rails_helper"

RSpec.describe "Curriculums & Folders", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  describe "curriculums" do
    it "groups courses in order" do
      curriculum = create(:curriculum, workspace: workspace)
      c1 = create(:course, workspace: workspace)
      c2 = create(:course, workspace: workspace)

      post app_curriculum_items_path(curriculum), params: { course_id: c1.id }
      post app_curriculum_items_path(curriculum), params: { course_id: c2.id }

      expect(curriculum.reload.courses).to eq([ c1, c2 ])
    end

    it "lets a course belong to multiple curriculums" do
      course = create(:course, workspace: workspace)
      a = create(:curriculum, workspace: workspace)
      b = create(:curriculum, workspace: workspace)
      post app_curriculum_items_path(a), params: { course_id: course.id }
      post app_curriculum_items_path(b), params: { course_id: course.id }
      expect(a.reload.courses).to include(course)
      expect(b.reload.courses).to include(course)
    end
  end

  describe "folders" do
    it "creates nested folders and moves a note into one" do
      post app_folders_path, params: { name: "BJJ" }
      parent = Folder.last
      post app_folders_path, params: { name: "Guard", parent_id: parent.id }
      child = Folder.last
      expect(child.parent).to eq(parent)

      video = create(:video, workspace: workspace)
      note = create(:note, workspace: workspace, video: video)
      patch app_note_path(note), params: { folder_id: child.id }
      expect(note.reload.folder).to eq(child)
    end

    it "rejects a folder being its own parent" do
      folder = create(:folder, workspace: workspace)
      folder.update(parent_id: folder.id)
      expect(folder.errors[:parent]).to be_present
    end
  end
end
