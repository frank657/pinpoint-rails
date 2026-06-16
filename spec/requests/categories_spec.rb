require "rails_helper"

RSpec.describe "Categories management", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  describe "GET /categories" do
    it "renders the management page with names and note counts" do
      sweeps = create(:category, workspace: workspace, name: "Sweeps")
      create(:note, workspace: workspace, category: sweeps)
      create(:category, workspace: workspace, name: "Passes")

      get app_categories_path, headers: inertia_headers
      cats = inertia_props(response).fetch("categories")
      expect(cats.map { |c| c["name"] }).to contain_exactly("Sweeps", "Passes")
      expect(cats.find { |c| c["name"] == "Sweeps" }["count"]).to eq(1)
    end
  end

  describe "create / rename / delete" do
    it "creates, renames and deletes" do
      expect { post app_categories_path, params: { name: "Escapes" } }.to change(Category, :count).by(1)
      cat = Category.last
      patch app_category_path(cat), params: { name: "Escapes 2" }
      expect(cat.reload.name).to eq("Escapes 2")
      expect { delete app_category_path(cat) }.to change(Category, :count).by(-1)
    end

    it "nullifies note category on delete (does not destroy notes)" do
      cat = create(:category, workspace: workspace, name: "Doomed")
      note = create(:note, workspace: workspace, category: cat)
      delete app_category_path(cat)
      expect(note.reload.category_id).to be_nil
    end
  end

  describe "POST /categories/:id/merge" do
    it "re-files notes onto the target and deletes the source" do
      source = create(:category, workspace: workspace, name: "BJJ")
      target = create(:category, workspace: workspace, name: "Jiu-jitsu")
      note = create(:note, workspace: workspace, category: source)

      post merge_app_category_path(source), params: { target_id: target.id }

      expect(Category.exists?(source.id)).to be(false)
      expect(note.reload.category_id).to eq(target.id)
    end
  end
end
