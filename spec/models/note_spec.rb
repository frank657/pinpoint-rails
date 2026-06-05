require "rails_helper"

RSpec.describe Note, type: :model do
  let(:workspace) { create(:user).workspaces.first }
  before { ActsAsTenant.current_tenant = workspace }

  it { is_expected.to define_enum_for(:note_type).with_values(timestamp: 0, rich_text: 1) }

  describe "validations" do
    it "requires a video and start_seconds for a timestamp note" do
      note = build(:note, video: nil, start_seconds: nil)
      expect(note).not_to be_valid
      expect(note.errors[:video]).to be_present
      expect(note.errors[:start_seconds]).to be_present
    end

    it "allows a rich_text note with no video or timestamp" do
      expect(build(:note, :rich_text)).to be_valid
    end

    it "rejects an end before the start" do
      expect(build(:note, start_seconds: 30, end_seconds: 10)).not_to be_valid
    end
  end

  it "stores timestamps as numeric seconds" do
    note = create(:note, start_seconds: 12.5, end_seconds: 30.25)
    expect(note.start_seconds).to eq(12.5)
    expect(note).to be_range
  end

  it "stores an Action Text rich body" do
    note = create(:note, :rich_text, body: "<div>Step <strong>one</strong></div>")
    expect(note.body.to_plain_text).to include("Step one")
  end

  describe "full-text search" do
    it "finds notes by title" do
      match = create(:note, title: "Closed guard sweep")
      create(:note, title: "Mount escape")
      expect(Note.search("guard")).to include(match)
    end
  end
end
