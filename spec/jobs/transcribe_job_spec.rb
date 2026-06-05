require "rails_helper"

RSpec.describe TranscribeJob, type: :job do
  let(:workspace) { create(:workspace) }

  before { stub_aliyun! }

  it "writes timestamped transcript lines from the (stubbed) AI provider" do
    video = ActsAsTenant.with_tenant(workspace) { create(:video, :upload, workspace: workspace) }

    allow(Ai).to receive(:transcribe).and_return([
      { start_seconds: 0.0, text: "First line." },
      { start_seconds: 4.0, text: "Second line." }
    ])

    described_class.perform_now(video.id, workspace.id)

    lines = ActsAsTenant.with_tenant(workspace) { TranscriptLine.for_video(video).to_a }
    expect(lines.map(&:text)).to eq([ "First line.", "Second line." ])
    expect(lines.map(&:start_seconds)).to eq([ 0.0, 4.0 ])
  end

  it "does not clobber an existing imported transcript" do
    video = ActsAsTenant.with_tenant(workspace) do
      v = create(:video, :upload, workspace: workspace)
      v.transcript_lines.create!(start_seconds: 1.0, text: "Imported", position: 0)
      v
    end
    expect(Ai).not_to receive(:transcribe)

    described_class.perform_now(video.id, workspace.id)

    count = ActsAsTenant.with_tenant(workspace) { video.transcript_lines.count }
    expect(count).to eq(1)
  end
end
