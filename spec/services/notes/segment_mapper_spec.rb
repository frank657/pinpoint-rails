require "rails_helper"

# The executable contract for ADR 0011 — one example per scenario row. Mapping is driven by
# model callbacks (Note/Video::Segment) delegating to Notes::SegmentMapper, so these create real
# records and assert the stored segment_id.
RSpec.describe Notes::SegmentMapper, type: :model do
  let(:workspace) { create(:user).workspaces.first }
  let(:video) { create(:video, workspace: workspace) }

  around { |ex| ActsAsTenant.with_tenant(workspace, &ex) }

  def seg(start_s, end_s, **extra)
    create(:segment, video: video, workspace: workspace, start_seconds: start_s, end_seconds: end_s, **extra)
  end

  def tnote(start_s, **extra)
    create(:note, video: video, workspace: workspace, start_seconds: start_s, **extra)
  end

  it "#1 adopts a note whose start falls in one closed segment" do
    s = seg(0, 60)
    expect(tnote(30).segment).to eq(s)
  end

  it "#2 on overlap, the earliest-created segment wins" do
    first  = seg(0, 60)
    _second = seg(0, 60)
    expect(tnote(30).segment).to eq(first)
  end

  it "#3 a note in a gap / before any segment stays loose" do
    seg(0, 60)
    expect(tnote(120).segment).to be_nil
  end

  it "#4 an untimed note is never mapped" do
    seg(0, 60)
    expect(create(:note, :rich_text, workspace: workspace).segment).to be_nil
  end

  it "#5 an open-ended segment owns nothing" do
    seg(0, nil)
    expect(tnote(30).segment).to be_nil
  end

  it "#6 a new closed segment adopts existing orphan notes in range" do
    n = tnote(30)
    expect(n.segment).to be_nil
    s = seg(0, 60)
    expect(n.reload.segment).to eq(s)
  end

  it "#7 a new overlapping segment does not steal already-pinned notes" do
    first = seg(0, 60)
    n = tnote(30)
    expect(n.segment).to eq(first)
    seg(0, 60) # second, overlapping
    expect(n.reload.segment).to eq(first)
  end

  it "#8 a newly created open-ended segment adopts nothing" do
    n = tnote(30)
    seg(0, nil)
    expect(n.reload.segment).to be_nil
  end

  it "#9 setting an end on an open-ended segment adopts orphans now in range" do
    n = tnote(30)
    s = seg(0, nil)
    expect(n.reload.segment).to be_nil
    s.update!(end_seconds: 60)
    expect(n.reload.segment).to eq(s)
  end

  it "#10 extending a segment's end adopts newly-covered orphans" do
    n = tnote(90)
    s = seg(0, 60)
    expect(n.reload.segment).to be_nil
    s.update!(end_seconds: 120)
    expect(n.reload.segment).to eq(s)
  end

  it "#11 shrinking a segment's end does not evict pinned notes" do
    s = seg(0, 120)
    n = tnote(90)
    expect(n.segment).to eq(s)
    s.update!(end_seconds: 60)
    expect(n.reload.segment).to eq(s) # still pinned, time now outside (#16)
  end

  it "#12 deleting a segment orphans its notes (no auto re-home)" do
    s = seg(0, 60)
    n = tnote(30)
    expect(n.segment).to eq(s)
    s.destroy!
    expect(n.reload.segment_id).to be_nil
  end

  it "#15 editing the start of an orphan re-evaluates; a pinned note stays put" do
    later = seg(60, 120)
    orphan = tnote(30)
    expect(orphan.segment).to be_nil
    orphan.update!(start_seconds: 90)
    expect(orphan.reload.segment).to eq(later) # orphan adopted

    pinned_home = seg(0, 30)
    pinned = tnote(10)
    expect(pinned.segment).to eq(pinned_home)
    pinned.update!(start_seconds: 90)
    expect(pinned.reload.segment).to eq(pinned_home) # pinned never auto-remaps
  end

  it "is workspace-scoped — a segment in another workspace never adopts" do
    other_ws = create(:user).workspaces.first
    ActsAsTenant.with_tenant(other_ws) { create(:segment, workspace: other_ws, start_seconds: 0, end_seconds: 60) }
    expect(tnote(30).segment).to be_nil # only this video's/workspace's segments considered
  end
end
