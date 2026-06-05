module App
  class CurriculumsController < BaseController
    def index
      render inertia: "curriculums/Index", props: {
        curriculums: Curriculum.order(:title).map { |c| { id: c.id, slug: c.slug, title: c.title, courseCount: c.items.size } }
      }
    end

    def show
      curriculum = Curriculum.friendly.find(params[:id])
      authorize! curriculum, to: :show?
      render inertia: "curriculums/Show", props: {
        curriculum: {
          id: curriculum.id, slug: curriculum.slug, title: curriculum.title, description: curriculum.description,
          items: curriculum.items.includes(:course).map { |i|
            { id: i.id, courseId: i.course_id, courseTitle: i.course.title, courseSlug: i.course.slug, position: i.position }
          }
        },
        availableCourses: Course.order(:title).map { |c| { id: c.id, title: c.title } }
      }
    end

    def create
      curriculum = Curriculum.create!(title: params[:title].presence || "Untitled curriculum", description: params[:description])
      redirect_to app_curriculum_path(curriculum)
    end

    def update
      curriculum = Curriculum.friendly.find(params[:id])
      authorize! curriculum, to: :update?
      curriculum.update!(params.permit(:title, :description))
      redirect_to app_curriculum_path(curriculum)
    end

    def destroy
      curriculum = Curriculum.friendly.find(params[:id])
      authorize! curriculum, to: :destroy?
      curriculum.destroy!
      redirect_to app_curriculums_path, notice: "Curriculum deleted."
    end
  end
end
