require "rails_helper"

RSpec.describe "Videos", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }

  before do
    host! "app.lvh.me"
    sign_in user
    # Tenant-scoped assertions (Video.count etc.) run in the spec context, which has no
    # request — set the current tenant so those queries don't raise (require_tenant).
    ActsAsTenant.current_tenant = workspace
  end

  describe "POST /videos/youtube" do
    it "ingests a YouTube link into a new video" do
      allow(Youtube::Ingest).to receive(:call).and_return(
        Youtube::Ingest::Result.new(youtube_id: "abc12345678", title: "Closed Guard", duration_seconds: 120, thumbnail_url: nil)
      )

      expect {
        post app_youtube_videos_path, params: { url: "https://youtu.be/abc12345678" }
      }.to change(Video, :count).by(1)

      video = Video.last
      expect(video).to be_youtube
      expect(video.title).to eq("Closed Guard")
      expect(response).to redirect_to(app_video_path(video))
    end

    it "reports an error for a non-YouTube link" do
      allow(Youtube::Ingest).to receive(:call).and_raise(Youtube::Ingest::InvalidUrl)
      post app_youtube_videos_path, params: { url: "https://example.com" }
      expect(response).to redirect_to(app_videos_path)
    end
  end

  describe "GET /videos" do
    it "lists only the current workspace's videos" do
      mine = ActsAsTenant.with_tenant(workspace) { create(:video, workspace: workspace, title: "Mine") }
      other = create(:user).workspaces.first
      ActsAsTenant.with_tenant(other) { create(:video, workspace: other, title: "Theirs") }

      get app_videos_path, headers: inertia_headers
      titles = inertia_props(response)["videos"].map { |v| v["title"] }
      expect(titles).to eq([ "Mine" ])
      expect(inertia_props(response)["videos"].first["id"]).to eq(mine.id)
    end
  end

  describe "GET /videos/:id (youtube)" do
    it "returns playback data for the embed" do
      video = ActsAsTenant.with_tenant(workspace) { create(:video, workspace: workspace, youtube_id: "abc12345678") }
      get app_video_path(video), headers: inertia_headers
      playback = inertia_props(response)["playback"]
      expect(playback["source"]).to eq("youtube")
      expect(playback["youtubeId"]).to eq("abc12345678")
    end
  end

  describe "GET /videos/:id/status" do
    it "reports upload status as JSON" do
      stub_aliyun!
      video = ActsAsTenant.with_tenant(workspace) { create(:video, :upload, workspace: workspace) }
      get status_app_video_path(video)
      expect(JSON.parse(response.body)["status"]).to eq("uploading")
    end
  end

  describe "POST /videos/upload (provision)" do
    it "creates a Vod + Video and returns OSS upload credentials" do
      stub_aliyun!(file_name: "lesson.mp4")
      expect {
        post app_video_uploads_path, params: { filename: "lesson.mp4", title: "Lesson 1" }
      }.to change(Video, :count).by(1).and change(Vod, :count).by(1)

      json = JSON.parse(response.body)
      expect(json["uploadAddress"]).to be_present
      expect(json["uploadAuth"]).to be_present
      expect(json["videoId"]).to eq(Video.last.id)
    end
  end

  describe "DELETE /videos/:id" do
    it "deletes the video" do
      video = ActsAsTenant.with_tenant(workspace) { create(:video, workspace: workspace) }
      expect { delete app_video_path(video) }.to change(Video, :count).by(-1)
    end
  end
end
