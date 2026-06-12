require "rails_helper"

RSpec.describe "Notebooks", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  it "creates a notebook and adds videos in order" do
    post app_notebooks_path, params: { title: "Closed Guard" }
    notebook = Notebook.last
    v1 = create(:video, workspace: workspace, title: "Intro")
    v2 = create(:video, workspace: workspace, title: "Sweep")

    post app_notebook_items_path(notebook), params: { video_id: v1.id }
    post app_notebook_items_path(notebook), params: { video_id: v2.id }

    expect(notebook.reload.videos).to eq([ v1, v2 ])
    expect(notebook.items.pluck(:position)).to eq([ 0, 1 ])
  end

  it "lets the same video belong to two notebooks independently (ADR 0010)" do
    video = create(:video, workspace: workspace)
    a = create(:notebook, workspace: workspace)
    b = create(:notebook, workspace: workspace)

    post app_notebook_items_path(a), params: { video_id: video.id }
    post app_notebook_items_path(b), params: { video_id: video.id }

    expect(a.reload.videos).to include(video)
    expect(b.reload.videos).to include(video)
  end

  it "reorders items" do
    notebook = create(:notebook, workspace: workspace)
    items = Array.new(3) { |i| notebook.items.create!(video: create(:video, workspace: workspace), position: i) }

    post reorder_app_notebook_items_path(notebook), params: { ids: items.reverse.map(&:id) }
    expect(response).to have_http_status(:ok)
    expect(notebook.items.order(:position).pluck(:id)).to eq(items.reverse.map(&:id))
  end

  it "removing a video from a notebook deletes the join but keeps the video" do
    notebook = create(:notebook, workspace: workspace)
    video = create(:video, workspace: workspace)
    item = notebook.items.create!(video: video)

    expect { delete app_notebook_item_path(notebook, item) }.to change(Notebook::Item, :count).by(-1)
    expect(Video.exists?(video.id)).to be(true)
  end

  it "deleting a video cleans up its notebook items" do
    notebook = create(:notebook, workspace: workspace)
    video = create(:video, workspace: workspace)
    notebook.items.create!(video: video)

    expect { video.destroy }.to change(Notebook::Item, :count).by(-1)
  end

  it "supports optional chapters and assigning items to them" do
    notebook = create(:notebook, workspace: workspace)
    post app_notebook_chapters_path(notebook), params: { title: "Basics" }
    chapter = notebook.chapters.last
    item = notebook.items.create!(video: create(:video, workspace: workspace))

    patch app_notebook_item_path(notebook, item), params: { notebook_chapter_id: chapter.id }
    expect(item.reload.chapter).to eq(chapter)
  end
end
