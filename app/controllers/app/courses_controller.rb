module App
  class CoursesController < BaseController
    def index
      render inertia: "courses/Index", props: {
        courses: Course.order(:title).map { |c| { id: c.id, slug: c.slug, title: c.title, videoCount: c.items.size } }
      }
    end

    def show
      course = Course.friendly.find(params[:id])
      authorize! course, to: :show?
      render inertia: "courses/Show", props: {
        course: course_detail(course),
        availableVideos: Video.order(created_at: :desc).map { |v| { id: v.id, title: v.title } }
      }
    end

    def create
      course = Course.create!(title: params[:title].presence || "Untitled course", description: params[:description])
      redirect_to app_course_path(course)
    end

    def update
      course = Course.friendly.find(params[:id])
      authorize! course, to: :update?
      course.update!(params.permit(:title, :description))
      redirect_to app_course_path(course)
    end

    def destroy
      course = Course.friendly.find(params[:id])
      authorize! course, to: :destroy?
      course.destroy!
      redirect_to app_courses_path, notice: "Course deleted."
    end

    private

    def course_detail(course)
      video_ids = course.items.pluck(:video_id)
      completed = Progress.completed.where(
        user: current_user, workspace: current_workspace, trackable_type: "Video", trackable_id: video_ids
      ).count
      {
        id: course.id, slug: course.slug, title: course.title, description: course.description,
        share: course.share && { id: course.share.id, token: course.share.token },
        progress: { completed: completed, total: video_ids.size },
        chapters: course.chapters.map { |ch| { id: ch.id, title: ch.title, position: ch.position } },
        items: course.items.includes(:video).map { |i|
          { id: i.id, videoId: i.video_id, videoTitle: i.video.title, chapterId: i.course_chapter_id, position: i.position }
        }
      }
    end
  end
end
