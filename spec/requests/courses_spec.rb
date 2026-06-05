require "rails_helper"

RSpec.describe "Courses", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  it "creates a course and adds videos in order" do
    post app_courses_path, params: { title: "Closed Guard" }
    course = Course.last
    v1 = create(:video, workspace: workspace, title: "Intro")
    v2 = create(:video, workspace: workspace, title: "Sweep")

    post app_course_items_path(course), params: { video_id: v1.id }
    post app_course_items_path(course), params: { video_id: v2.id }

    expect(course.reload.videos).to eq([ v1, v2 ])
    expect(course.items.pluck(:position)).to eq([ 0, 1 ])
  end

  it "lets the same video belong to two courses independently (ADR 0003)" do
    video = create(:video, workspace: workspace)
    a = create(:course, workspace: workspace)
    b = create(:course, workspace: workspace)

    post app_course_items_path(a), params: { video_id: video.id }
    post app_course_items_path(b), params: { video_id: video.id }

    expect(a.reload.videos).to include(video)
    expect(b.reload.videos).to include(video)
  end

  it "reorders items" do
    course = create(:course, workspace: workspace)
    items = Array.new(3) { |i| course.items.create!(video: create(:video, workspace: workspace), position: i) }

    post reorder_app_course_items_path(course), params: { ids: items.reverse.map(&:id) }
    expect(response).to have_http_status(:ok)
    expect(course.items.order(:position).pluck(:id)).to eq(items.reverse.map(&:id))
  end

  it "removing a video from a course deletes the join but keeps the video" do
    course = create(:course, workspace: workspace)
    video = create(:video, workspace: workspace)
    item = course.items.create!(video: video)

    expect { delete app_course_item_path(course, item) }.to change(Course::Item, :count).by(-1)
    expect(Video.exists?(video.id)).to be(true)
  end

  it "deleting a video cleans up its course items" do
    course = create(:course, workspace: workspace)
    video = create(:video, workspace: workspace)
    course.items.create!(video: video)

    expect { video.destroy }.to change(Course::Item, :count).by(-1)
  end

  it "supports optional chapters and assigning items to them" do
    course = create(:course, workspace: workspace)
    post app_course_chapters_path(course), params: { title: "Basics" }
    chapter = course.chapters.last
    item = course.items.create!(video: create(:video, workspace: workspace))

    patch app_course_item_path(course, item), params: { course_chapter_id: chapter.id }
    expect(item.reload.chapter).to eq(chapter)
  end
end
