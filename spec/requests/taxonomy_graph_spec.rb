require "rails_helper"

RSpec.describe "Technique taxonomy graph", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  it "loads the BJJ seed taxonomy" do
    expect {
      post seed_app_positions_path
    }.to change(Position, :count).by(9).and change(Technique, :count).by(7)
  end

  it "tags a note with positions, separate from free tags" do
    video = create(:video, workspace: workspace)
    position = Position.create!(name: "Closed Guard", category: :guard, dominance: :neutral)

    post app_notes_path, params: {
      note_type: "timestamp", video_id: video.id, start_seconds: "5", title: "Grip",
      tag_names: [ "grips" ], position_ids: [ position.id ]
    }
    note = Note.last
    expect(note.positions).to eq([ position ])
    expect(note.tags.map(&:name)).to eq([ "grips" ])
    # Free tags and positions are distinct systems
    expect(Tag.where(name: "Closed Guard")).to be_empty
  end

  it "aggregates notes on a position page" do
    video = create(:video, workspace: workspace)
    position = Position.create!(name: "Mount", category: :pin, dominance: :dominant)
    note = create(:note, workspace: workspace, video: video, title: "Mount maintenance")
    note.positions << position

    get app_position_path(position), headers: inertia_headers
    titles = inertia_props(response)["notes"].map { |n| n["title"] }
    expect(titles).to include("Mount maintenance")
  end

  it "models techniques as typed edges between positions" do
    post seed_app_positions_path
    get app_positions_path, headers: inertia_headers
    edge = inertia_props(response)["techniques"].find { |t| t["name"] == "Scissor Sweep" }
    expect(edge).to include("from" => "Closed Guard", "to" => "Mount", "kind" => "sweep")
  end
end
