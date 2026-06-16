require "rails_helper"

RSpec.describe "Search", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }
  let(:video) { create(:video, workspace: workspace, title: "Closed Guard") }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  it "finds notes by title and deep-links to the moment" do
    create(:note, workspace: workspace, video: video, title: "Scissor sweep details")

    get app_search_path(q: "scissor"), headers: inertia_headers
    notes = inertia_props(response)["results"]["notes"]
    expect(notes.map { |n| n["title"] }).to include("Scissor sweep details")
    expect(notes.first).to include("videoId" => video.id)
  end

  it "returns empty results for a blank query" do
    get app_search_path, headers: inertia_headers
    expect(inertia_props(response)["results"]).to eq("notes" => [], "videos" => [])
  end

  it "finds videos by title, tag and featured athlete" do
    by_title = create(:video, workspace: workspace, title: "Triangle finishes")
    by_tag = create(:video, workspace: workspace, title: "Untitled A")
    by_tag.tag_names = [ "triangle" ]
    by_athlete = create(:video, workspace: workspace, title: "Untitled B")
    by_athlete.athlete_names = [ "Triangle Joe" ]

    get app_search_query_path(q: "triangle")
    ids = JSON.parse(response.body)["videos"].map { |v| v["id"] }
    expect(ids).to contain_exactly(by_title.id, by_tag.id, by_athlete.id)
  end
end
