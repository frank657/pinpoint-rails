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
    # Never hit the network for chapters — stub the seam (default: no chapters).
    before { allow(Youtube::Chapters).to receive(:call).and_return([]) }

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

    it "imports the video's chapters as segments on creation" do
      allow(Youtube::Ingest).to receive(:call).and_return(
        Youtube::Ingest::Result.new(youtube_id: "abc12345678", title: "Closed Guard", duration_seconds: 300, thumbnail_url: nil)
      )
      allow(Youtube::Chapters).to receive(:call).and_return([
        { start_seconds: 0.0, end_seconds: 60.0, title: "Intro" },
        { start_seconds: 60.0, end_seconds: 300.0, title: "Sweep" }
      ])

      post app_youtube_videos_path, params: { url: "https://youtu.be/abc12345678" }

      video = Video.last
      expect(video.segments.order(:position).pluck(:title)).to eq([ "Intro", "Sweep" ])
      expect(video.segments.order(:position).first).to have_attributes(start_seconds: 0.0, end_seconds: 60.0)
    end

    it "still adds the video when chapter import fails (best-effort)" do
      allow(Youtube::Ingest).to receive(:call).and_return(
        Youtube::Ingest::Result.new(youtube_id: "abc12345678", title: "Closed Guard", duration_seconds: 120, thumbnail_url: nil)
      )
      allow(Youtube::Chapters).to receive(:call).and_raise(StandardError, "boom")

      expect {
        post app_youtube_videos_path, params: { url: "https://youtu.be/abc12345678" }
      }.to change(Video, :count).by(1)
      expect(response).to redirect_to(app_video_path(Video.last))
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

  describe "GET /videos (Library v2)" do
    it "enriches each card with note count, athletes, tags and a poster" do
      video = ActsAsTenant.with_tenant(workspace) do
        v = create(:video, workspace: workspace, title: "Guard passing", youtube_id: "passpass123")
        create(:note, workspace: workspace, video: v, title: "n1")
        v.tag_names = [ "passing" ]
        v.athlete_names = [ "Gordon Ryan" ]
        v
      end

      get app_videos_path, headers: inertia_headers
      card = inertia_props(response)["videos"].find { |c| c["id"] == video.id }
      expect(card["noteCount"]).to eq(1)
      expect(card["tags"]).to contain_exactly("passing")
      expect(card["athletes"]).to contain_exactly("Gordon Ryan")
      expect(card["poster"]).to include("passpass123")
    end

    it "exposes the available filter facets" do
      ActsAsTenant.with_tenant(workspace) do
        create(:tag, workspace: workspace, name: "leglocks")
        create(:athlete, workspace: workspace, name: "Lachlan Giles")
      end
      get app_videos_path, headers: inertia_headers
      props = inertia_props(response)
      expect(props["tags"]).to include("leglocks")
      expect(props["athletes"]).to include("Lachlan Giles")
      expect(props["sources"]).to contain_exactly("upload", "youtube")
    end

    it "filters by tag, athlete, source and title query" do
      tagged = ActsAsTenant.with_tenant(workspace) do
        v = create(:video, workspace: workspace, title: "Closed guard")
        v.tag_names = [ "sweep" ]
        v
      end
      featured = ActsAsTenant.with_tenant(workspace) do
        v = create(:video, workspace: workspace, title: "Berimbolo")
        v.athlete_names = [ "Mikey" ]
        v
      end
      ActsAsTenant.with_tenant(workspace) { create(:video, workspace: workspace, title: "Unrelated") }

      get app_videos_path, params: { tag: "sweep" }, headers: inertia_headers
      expect(inertia_props(response)["videos"].map { |v| v["id"] }).to eq([ tagged.id ])

      get app_videos_path, params: { athlete: "Mikey" }, headers: inertia_headers
      expect(inertia_props(response)["videos"].map { |v| v["id"] }).to eq([ featured.id ])

      get app_videos_path, params: { q: "berimbolo" }, headers: inertia_headers
      expect(inertia_props(response)["videos"].map { |v| v["title"] }).to eq([ "Berimbolo" ])

      get app_videos_path, params: { source: "youtube" }, headers: inertia_headers
      expect(inertia_props(response)["videos"].length).to eq(3)
    end

    it "filters by added-date range" do
      old = ActsAsTenant.with_tenant(workspace) { create(:video, workspace: workspace, title: "Old", created_at: 10.days.ago) }
      recent = ActsAsTenant.with_tenant(workspace) { create(:video, workspace: workspace, title: "New", created_at: 1.day.ago) }

      get app_videos_path, params: { added_from: 3.days.ago.to_date.iso8601 }, headers: inertia_headers
      ids = inertia_props(response)["videos"].map { |v| v["id"] }
      expect(ids).to include(recent.id)
      expect(ids).not_to include(old.id)
    end
  end

  describe "PATCH /videos/:id (tags & athletes)" do
    it "assigns tags and athletes to a video" do
      video = ActsAsTenant.with_tenant(workspace) { create(:video, workspace: workspace) }
      patch app_video_path(video), params: { tag_names: [ "highlight" ], athlete_names: [ "Gordon Ryan" ] }
      expect(video.reload.tag_names).to contain_exactly("highlight")
      expect(video.athlete_names).to contain_exactly("Gordon Ryan")
    end
  end

  describe "PATCH /videos/:id (video-level taxonomy & description)" do
    it "assigns categories, positions, techniques and a description" do
      category = nil
      position = nil
      technique = nil
      video = ActsAsTenant.with_tenant(workspace) do
        category = create(:category, name: "Sweeps")
        position = Position.create!(name: "Ashi Garami", category: :guard, dominance: :neutral)
        technique = Technique.create!(name: "Foot sweep", kind: :takedown)
        create(:video, workspace: workspace)
      end

      patch app_video_path(video), params: {
        description: "<p>Great <strong>entry</strong></p>",
        category_ids: [ category.id ], position_ids: [ position.id ], technique_ids: [ technique.id ]
      }

      video.reload
      expect(video.categories).to contain_exactly(category)
      expect(video.positions).to contain_exactly(position)
      expect(video.techniques).to contain_exactly(technique)
      expect(video.description).to include("entry")
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

    it "serializes video-level taxonomy, description and athletes as avatar objects" do
      video = ActsAsTenant.with_tenant(workspace) do
        v = create(:video, workspace: workspace, description: "<p>hi</p>")
        v.categories = [ create(:category, name: "Sweeps") ]
        v.athletes = [ create(:athlete, name: "John Danaher") ]
        v
      end

      get app_video_path(video), headers: inertia_headers
      props = inertia_props(response)["video"]

      expect(props["description"]).to include("hi")
      expect(props["categories"].map { |c| c["name"] }).to contain_exactly("Sweeps")
      athlete = props["athletes"].first
      expect(athlete).to include("name" => "John Danaher", "initials" => "JD")
      expect(athlete).to have_key("avatarUrl")
      expect(athlete["hue"]).to be_between(0, 359)
    end
  end

  describe "GET /videos/:id (upload)" do
    it "returns hlsUrl when vod is ready" do
      stub_aliyun!
      vod = ActsAsTenant.without_tenant { create(:vod, :ready, uploaded_by: user) }
      video = ActsAsTenant.with_tenant(workspace) { create(:video, :upload, workspace: workspace, vod: vod) }

      # Stub url() so we don't hit Aliyun for the HLS URL
      allow_any_instance_of(VodService::Aliyun::Video).to receive(:transcoded_url).and_return("https://cdn.example.com/v.m3u8")

      get app_video_path(video), headers: inertia_headers
      playback = inertia_props(response)["playback"]
      expect(playback["source"]).to eq("upload")
      expect(playback["status"]).to eq("ready")
      expect(playback["hlsUrl"]).to eq("https://cdn.example.com/v.m3u8")
    end

    it "returns mediaUrl when vod is uploaded (mezzanine playable immediately)" do
      stub_aliyun!
      vod = ActsAsTenant.without_tenant { create(:vod, :uploaded, uploaded_by: user) }
      video = ActsAsTenant.with_tenant(workspace) { create(:video, :upload, workspace: workspace, vod: vod) }

      allow_any_instance_of(VodService::Aliyun::Video).to receive(:mezzanine_url).and_return("https://oss.example.com/raw.mp4")
      # uploaded? vod — sync_from_provider! won't advance since provider_play_info is stubbed empty
      allow_any_instance_of(VodService::Aliyun::Video).to receive(:provider_play_info).and_return(nil)

      get app_video_path(video), headers: inertia_headers
      playback = inertia_props(response)["playback"]
      expect(playback["source"]).to eq("upload")
      expect(playback["status"]).to eq("uploaded")
      expect(playback["mediaUrl"]).to eq("https://oss.example.com/raw.mp4")
    end

    it "shows uploading placeholder when vod is still uploading and Aliyun has nothing yet" do
      stub_aliyun!
      video = ActsAsTenant.with_tenant(workspace) { create(:video, :upload, workspace: workspace) }

      allow_any_instance_of(VodService::Aliyun::Video).to receive(:provider_play_info).and_return(nil)
      allow_any_instance_of(VodService::Aliyun::Video).to receive(:uploaded?).and_return(false)

      get app_video_path(video), headers: inertia_headers
      playback = inertia_props(response)["playback"]
      expect(playback["hlsUrl"]).to be_nil
      expect(playback["mediaUrl"]).to be_nil
      expect(playback["status"]).to eq("uploading")
    end
  end

  describe "GET /videos/:id/status" do
    it "reports upload status as JSON" do
      stub_aliyun!
      video = ActsAsTenant.with_tenant(workspace) { create(:video, :upload, workspace: workspace) }
      get status_app_video_path(video)
      expect(JSON.parse(response.body)["status"]).to eq("uploading")
    end

    it "reconciles to ready when Aliyun has transcoded (webhook-unreachable scenario)" do
      stub_aliyun!
      video = ActsAsTenant.with_tenant(workspace) { create(:video, :upload, workspace: workspace) }
      vod = video.vod
      expect(vod).to be_uploading

      # Simulate Aliyun having transcoded the asset (provider_play_info returns play info)
      play_info = [ { status: "Normal", format: "m3u8", definition: "AUTO",
                      play_url: "https://cdn.example.com/v.m3u8", duration: 42.0,
                      size: 1_000_000, height: 1080, width: 1920 } ]
      allow_any_instance_of(VodService::Aliyun::Video).to receive(:provider_play_info).and_return(play_info)

      get status_app_video_path(video)

      expect(vod.reload).to be_ready
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("ready")
      expect(json["playable"]).to be true
    end
  end

  describe "POST /vod/direct_uploads" do
    it "provisions a Vod only (no Video yet) and returns STS credentials" do
      stub_aliyun!(file_name: "lesson.mp4")
      expect {
        post app_vod_direct_uploads_path, params: { filename: "lesson.mp4", title: "Lesson 1" }
      }.to change(Vod, :count).by(1)
      expect(Video.count).to eq(0)

      json = JSON.parse(response.body)
      expect(json["signedId"]).to be_present
      expect(json["uploadAddress"]).to be_present
      expect(json["uploadAuth"]).to be_present
    end
  end

  describe "POST /videos (create from signed_id)" do
    it "creates a Video once the Vod is uploaded" do
      stub_aliyun!
      vod = ActsAsTenant.without_tenant { create(:vod, :uploaded, uploaded_by: user) }
      signed_id = vod.signed_id(purpose: :vod_upload, expires_in: 2.hours)

      expect {
        post app_videos_path, params: { signed_id: signed_id, title: "Lesson 1" }
      }.to change(Video, :count).by(1)

      video = Video.last
      expect(video.title).to eq("Lesson 1")
      expect(video.vod).to eq(vod)
      expect(video).to be_upload
      expect(JSON.parse(response.body)["videoId"]).to eq(video.id)
    end

    it "rejects a signed_id owned by another user" do
      stub_aliyun!
      other = create(:user)
      vod = ActsAsTenant.without_tenant { create(:vod, :uploaded, uploaded_by: other) }
      signed_id = vod.signed_id(purpose: :vod_upload, expires_in: 2.hours)

      expect {
        post app_videos_path, params: { signed_id: signed_id, title: "Stolen" }
      }.not_to change(Video, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "rejects a Vod that hasn't been uploaded yet" do
      stub_aliyun!
      vod = ActsAsTenant.without_tenant { create(:vod, status: :uploading, uploaded_by: user) }
      signed_id = vod.signed_id(purpose: :vod_upload, expires_in: 2.hours)

      expect {
        post app_videos_path, params: { signed_id: signed_id, title: "Too soon" }
      }.not_to change(Video, :count)
    end
  end

  describe "DELETE /videos/:id" do
    it "deletes the video" do
      video = ActsAsTenant.with_tenant(workspace) { create(:video, workspace: workspace) }
      expect { delete app_video_path(video) }.to change(Video, :count).by(-1)
    end
  end
end
