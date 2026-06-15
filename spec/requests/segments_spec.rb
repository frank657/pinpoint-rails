require "rails_helper"

RSpec.describe "Segments", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }
  let(:video) { create(:video, workspace: workspace) }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  it "creates a labeled segment with a numeric range and auto position" do
    expect {
      post app_segments_path, params: { video_id: video.id, title: "Warmup", start_seconds: "0", end_seconds: "60" }
    }.to change(Video::Segment, :count).by(1)

    segment = Video::Segment.last
    expect(segment.start_seconds).to eq(0.0)
    expect(segment.end_seconds).to eq(60.0)
    expect(segment.position).to eq(0)
    expect(response).to redirect_to(app_video_path(video))
  end

  it "increments position for subsequent segments on the same video" do
    post app_segments_path, params: { video_id: video.id, start_seconds: "0", title: "A" }
    post app_segments_path, params: { video_id: video.id, start_seconds: "10", title: "B" }
    expect(Video::Segment.order(:position).pluck(:position)).to eq([ 0, 1 ])
  end

  it "updates and deletes a segment" do
    segment = create(:segment, workspace: workspace, video: video)
    patch app_segment_path(segment), params: { title: "Renamed" }
    expect(segment.reload.title).to eq("Renamed")
    expect { delete app_segment_path(segment) }.to change(Video::Segment, :count).by(-1)
  end
end
