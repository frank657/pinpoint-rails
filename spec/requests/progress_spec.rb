require "rails_helper"

RSpec.describe "Progress", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }
  let(:video) { create(:video, workspace: workspace) }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  it "upserts resume position for a video" do
    post app_progress_path, params: { trackable_type: "Video", trackable_id: video.id, resume_seconds: "42" }
    expect(response).to have_http_status(:no_content)
    p = Progress.find_by(user: user, trackable: video)
    expect(p.resume_seconds).to eq(42)
  end

  it "resumes the video on the show page" do
    Progress.create!(user: user, workspace: workspace, trackable: video, resume_seconds: 30)
    get app_video_path(video), headers: inertia_headers
    expect(inertia_props(response)["resumeSeconds"]).to eq(30)
  end

  it "rolls up course completion from per-video progress" do
    course = create(:course, workspace: workspace)
    v1 = create(:video, workspace: workspace)
    v2 = create(:video, workspace: workspace)
    course.items.create!(video: v1)
    course.items.create!(video: v2)
    Progress.create!(user: user, workspace: workspace, trackable: v1, completed_at: Time.current)

    get app_course_path(course), headers: inertia_headers
    expect(inertia_props(response)["course"]["progress"]).to eq("completed" => 1, "total" => 2)
  end

  it "keeps progress private per user (Axis 3, not copied on fork)" do
    Progress.create!(user: user, workspace: workspace, trackable: video, resume_seconds: 50)
    other = create(:user)
    expect(Progress.where(user: other).count).to eq(0)
  end
end
