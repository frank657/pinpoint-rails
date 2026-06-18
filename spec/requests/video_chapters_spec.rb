require "rails_helper"

# POST /videos/:id/import_chapters — turns the YouTube-derived chapters into Segments.
# Youtube::Chapters (the network seam) is stubbed; we assert the create/idempotency/auth behavior.
RSpec.describe "Importing YouTube chapters", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }
  let(:video) { create(:video, workspace: workspace, duration_seconds: 1200) } # factory default is YouTube

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  def stub_chapters(entries)
    allow(Youtube::Chapters).to receive(:call).and_return(entries)
  end

  it "creates a segment per chapter, ordered by position" do
    stub_chapters([
      { title: "Intro", start_seconds: 0.0, end_seconds: 60.0 },
      { title: "Single", start_seconds: 60.0, end_seconds: 1200.0 }
    ])

    expect {
      post import_chapters_app_video_path(video)
    }.to change(Video::Segment, :count).by(2)

    segments = Video::Segment.for_video(video)
    expect(segments.map(&:title)).to eq(%w[Intro Single])
    expect(segments.map(&:start_seconds)).to eq([ 0.0, 60.0 ])
    expect(segments.map(&:position)).to eq([ 0, 1 ])
    expect(response).to redirect_to(app_video_path(video))
  end

  it "is idempotent — re-importing skips chapters whose start time already has a segment" do
    create(:segment, video: video, workspace: workspace, title: "Intro", start_seconds: 0.0)
    stub_chapters([
      { title: "Intro", start_seconds: 0.0, end_seconds: 60.0 },
      { title: "Single", start_seconds: 60.0, end_seconds: nil }
    ])

    expect {
      post import_chapters_app_video_path(video)
    }.to change(Video::Segment, :count).by(1) # only "Single" is new

    expect(Video::Segment.for_video(video).map(&:title)).to eq(%w[Intro Single])
  end

  it "reports gracefully when no chapters are found" do
    stub_chapters([])
    expect { post import_chapters_app_video_path(video) }.not_to change(Video::Segment, :count)
    expect(response).to redirect_to(app_video_path(video))
    follow_redirect!
    expect(flash[:notice]).to match(/No chapters found/i)
  end

  it "refuses for non-YouTube (upload) videos" do
    stub_aliyun!
    upload = create(:video, :upload, workspace: workspace)
    expect(Youtube::Chapters).not_to receive(:call)
    post import_chapters_app_video_path(upload)
    expect(response).to redirect_to(app_video_path(upload))
  end

  it "can't reach a video in another workspace (tenant-scoped)" do
    other = create(:user).workspaces.first
    foreign = ActsAsTenant.with_tenant(other) { create(:video, workspace: other) }
    expect(Youtube::Chapters).not_to receive(:call)
    # The request's tenant is the signed-in user's workspace, so the foreign video is invisible -> 404.
    post import_chapters_app_video_path(foreign)
    expect(response).to have_http_status(:not_found)
  end
end
