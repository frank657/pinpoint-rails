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

    it "relinks copied notes to the copied segments (ADR 0011 #20)" do
      src = ActsAsTenant.with_tenant(ws_a) do
        v = create(:video, workspace: ws_a, youtube_id: "seg12345678", title: "Seg")
        seg = create(:segment, workspace: ws_a, video: v, title: "Chapter 1", start_seconds: 0, end_seconds: 60)
        create(:note, workspace: ws_a, video: v, title: "inside", start_seconds: 30) # auto-maps into seg
        expect(seg.notes.map(&:title)).to eq([ "inside" ])
        v
      end

      forked = ForkService.call(src, target_workspace: ws_b, forked_by: forker)
      ActsAsTenant.with_tenant(ws_b) do
        copied_seg = forked.segments.find_by(title: "Chapter 1")
        copied_note = forked.notes.find_by(title: "inside")
        expect(copied_note.segment).to eq(copied_seg) # links to the COPIED segment, not the source
        expect(copied_seg.id).not_to eq(ActsAsTenant.with_tenant(ws_a) { src.segments.first.id })
      end
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
      n = create(:note, workspace: ws_a, video: v, categories: [ create(:category, workspace: ws_a, name: "Sweeps") ])
      n.tags = Tag.for_names([ "guard" ]); n.save!
      n
    end

    forked = ForkService.call(note, target_workspace: ws_b, forked_by: forker)
    ActsAsTenant.with_tenant(ws_b) do
      expect(forked.categories).to be_empty
      expect(forked.tags).to be_empty
    end
  end
end
