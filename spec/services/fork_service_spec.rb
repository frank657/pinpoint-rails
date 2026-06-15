require "rails_helper"

RSpec.describe ForkService do
  let(:owner) { create(:user) }
  let(:ws_a) { owner.workspaces.first }
  let(:forker) { create(:user) }
  let(:ws_b) { forker.workspaces.first }

  describe "forking a video (ADR 0005)" do
    let!(:source) do
      ActsAsTenant.with_tenant(ws_a) do
        video = create(:video, workspace: ws_a, youtube_id: "abc12345678", title: "Intro")
        create(:note, workspace: ws_a, video: video, title: "Grip first")
        video
      end
    end

    it "deep-copies the subtree into the target workspace" do
      forked = ForkService.call(source, target_workspace: ws_b, forked_by: forker)

      ActsAsTenant.with_tenant(ws_b) do
        forked.reload
        expect(forked.workspace).to eq(ws_b)
        expect(forked.id).not_to eq(source.id)
        expect(forked.title).to eq("Intro")
        expect(forked.youtube_id).to eq("abc12345678") # media shared by reference
        expect(forked.notes.map(&:title)).to eq([ "Grip first" ]) # notes copied
      end
    end

    it "is fully independent of the source after forking" do
      forked = ForkService.call(source, target_workspace: ws_b, forked_by: forker)
      ActsAsTenant.with_tenant(ws_b) { forked.update!(title: "My version") }
      expect(ActsAsTenant.with_tenant(ws_a) { source.reload.title }).to eq("Intro")
    end

    it "records a Fork attribution" do
      forked = ForkService.call(source, target_workspace: ws_b, forked_by: forker)
      fork = Fork.find_by(target_type: "Video", target_id: forked.id.to_s)
      expect(fork.source_id).to eq(source.id.to_s)
      expect(fork.target_workspace).to eq(ws_b)
    end
  end

  it "shares the underlying Vod by reference when forking an uploaded video" do
    stub_aliyun!
    source_video = ActsAsTenant.with_tenant(ws_a) { create(:video, :upload, workspace: ws_a) }
    forked = ForkService.call(source_video, target_workspace: ws_b, forked_by: forker)

    expect(forked.vod_id).to eq(source_video.vod_id) # same Aliyun asset, no re-upload
    expect(forked.id).not_to eq(source_video.id)
    expect(forked.workspace).to eq(ws_b)
  end

  it "does not carry taxonomy (category/tags) over — forked notes start unlabelled" do
    note = ActsAsTenant.with_tenant(ws_a) do
      v = create(:video, workspace: ws_a)
      n = create(:note, workspace: ws_a, video: v, category: create(:category, workspace: ws_a, name: "Sweeps"))
      n.tags = Tag.for_names([ "guard" ]); n.save!
      n
    end

    forked = ForkService.call(note, target_workspace: ws_b, forked_by: forker)
    ActsAsTenant.with_tenant(ws_b) do
      expect(forked.category).to be_nil
      expect(forked.tags).to be_empty
    end
  end
end
