require "rails_helper"

RSpec.describe Youtube::ChapterParser do
  # The exact description from the "take someone down" video in the feature request — messy on
  # purpose: a stray colon, an "AD" marker, and an untimed "Part III" header.
  let(:description) do
    <<~DESC
      Join the #1 Online Wrestling Academy: https://example.com

      00:12 Part I: High Percentage Takedowns
      00:22 Double
      02:32: Single
      03:28 Snap Down
      05:43 AD
      06:16 Part II: Finish Consistently
      Part III:Shot Recovery
      12:58 Front Headlock
      18:32 Hand Fighting
    DESC
  end

  it "extracts a chapter per timestamped line, ignoring untimed text" do
    chapters = described_class.call(description, duration: 1200)

    expect(chapters.map { |c| c[:title] }).to eq([
      "Part I: High Percentage Takedowns", "Double", "Single", "Snap Down",
      "AD", "Part II: Finish Consistently", "Front Headlock", "Hand Fighting"
    ])
    # The untimed "Part III:Shot Recovery" header is dropped — no leading timestamp.
    expect(chapters.map { |c| c[:title] }).not_to include("Shot Recovery")
  end

  it "converts MM:SS to numeric seconds" do
    chapters = described_class.call(description)
    expect(chapters.first).to include(title: "Part I: High Percentage Takedowns", start_seconds: 12.0)
    expect(chapters.find { |c| c[:title] == "Single" }[:start_seconds]).to eq(152.0)
  end

  it "chains end_seconds to the next chapter's start, closing the ranges" do
    chapters = described_class.call(description, duration: 1200)
    expect(chapters[0]).to include(start_seconds: 12.0, end_seconds: 22.0)
    expect(chapters[1]).to include(start_seconds: 22.0, end_seconds: 152.0)
  end

  it "runs the last chapter to the video duration when known" do
    chapters = described_class.call(description, duration: 1200)
    expect(chapters.last).to include(title: "Hand Fighting", start_seconds: 1112.0, end_seconds: 1200.0)
  end

  it "leaves the last chapter open-ended when duration is unknown" do
    chapters = described_class.call(description)
    expect(chapters.last[:end_seconds]).to be_nil
  end

  it "leaves the last chapter open-ended when duration precedes its start (bad data)" do
    chapters = described_class.call(description, duration: 10)
    expect(chapters.last[:end_seconds]).to be_nil
  end

  it "parses H:MM:SS timestamps for long videos" do
    chapters = described_class.call("1:02:03 Deep section")
    expect(chapters.first[:start_seconds]).to eq(3723.0)
  end

  it "strips leading bullets and separators from titles" do
    chapters = described_class.call("- 0:00 - Intro\n• 1:30 Warmup")
    expect(chapters.map { |c| c[:title] }).to eq(%w[Intro Warmup])
  end

  it "keeps a nil title for a bare timestamp" do
    expect(described_class.call("0:30").first).to include(start_seconds: 30.0, title: nil)
  end

  it "de-dupes repeated timestamps, keeping the first label, and sorts out-of-order stamps" do
    chapters = described_class.call("2:00 Later\n0:30 First\n0:30 Dup")
    expect(chapters.map { |c| [ c[:start_seconds], c[:title] ] }).to eq([ [ 30.0, "First" ], [ 120.0, "Later" ] ])
  end

  it "returns [] when the text has no timestamps" do
    expect(described_class.call("just a normal description\nwith no chapters")).to eq([])
    expect(described_class.call(nil)).to eq([])
  end
end
