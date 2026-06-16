require "rails_helper"

RSpec.describe "Athletes", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  describe "GET /athletes" do
    it "lists athletes with their video counts, tenant-scoped" do
      gordon = create(:athlete, workspace: workspace, name: "Gordon Ryan")
      create(:video, workspace: workspace).athletes << gordon
      create(:athlete, workspace: workspace, name: "Nobody")

      other = create(:user).workspaces.first
      ActsAsTenant.with_tenant(other) { create(:athlete, workspace: other, name: "Elsewhere") }

      get app_athletes_path, headers: inertia_headers
      athletes = inertia_props(response).fetch("athletes")
      expect(athletes.map { |a| a["name"] }).to contain_exactly("Gordon Ryan", "Nobody")
      expect(athletes.find { |a| a["name"] == "Gordon Ryan" }["videoCount"]).to eq(1)
    end
  end

  describe "POST /athletes" do
    it "creates an athlete" do
      expect { post app_athletes_path, params: { name: "Lachlan Giles" } }.to change(Athlete, :count).by(1)
    end
  end

  describe "GET /athletes/:id" do
    it "shows every video featuring the athlete" do
      athlete = create(:athlete, workspace: workspace, name: "Mikey Musumeci")
      featured = create(:video, workspace: workspace, title: "Ashi garami", youtube_id: "mikey0000001")
      featured.athletes << athlete
      create(:video, workspace: workspace, title: "Unrelated")

      get app_athlete_path(athlete), headers: inertia_headers
      props = inertia_props(response)
      expect(props.dig("athlete", "name")).to eq("Mikey Musumeci")
      expect(props["videos"].map { |v| v["title"] }).to eq([ "Ashi garami" ])
      expect(props["videos"].first["poster"]).to include("mikey0000001")
    end
  end
end
