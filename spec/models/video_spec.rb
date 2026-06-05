require "rails_helper"

RSpec.describe Video, type: :model do
  let(:workspace) { create(:user).workspaces.first }
  before { ActsAsTenant.current_tenant = workspace }

  it { is_expected.to define_enum_for(:source).with_values(upload: 0, youtube: 1) }

  describe "validations" do
    it "requires a youtube_id for a youtube video" do
      expect(build(:video, source: :youtube, youtube_id: nil)).not_to be_valid
    end

    it "requires a vod for an upload video" do
      expect(build(:video, source: :upload, youtube_id: nil, vod: nil)).not_to be_valid
    end
  end

  describe "a youtube video" do
    subject(:video) { create(:video) }

    it { is_expected.to be_youtube }
    it { is_expected.to be_playable }
    it "reports ready status" do
      expect(video.upload_status).to eq("ready")
    end
  end

  describe "reference-counted vod cleanup (ADR 0005)" do
    it "destroys the shared vod only when the last referencing video is gone" do
      stub_aliyun!
      ws_a = create(:user).workspaces.first
      ws_b = create(:user).workspaces.first
      vod  = create(:vod)
      v_a  = ActsAsTenant.with_tenant(ws_a) { create(:video, :upload, vod: vod, workspace: ws_a) }
      v_b  = ActsAsTenant.with_tenant(ws_b) { create(:video, :upload, vod: vod, workspace: ws_b) }

      ActsAsTenant.with_tenant(ws_a) { v_a.destroy }
      expect(Vod.exists?(vod.id)).to be(true) # still referenced by v_b in another workspace

      ActsAsTenant.with_tenant(ws_b) { v_b.destroy }
      expect(Vod.exists?(vod.id)).to be(false) # last reference gone
    end
  end
end
