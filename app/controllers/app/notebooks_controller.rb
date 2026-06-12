module App
  class NotebooksController < BaseController
    def index
      render inertia: "notebooks/Index", props: {
        notebooks: Notebook.order(:title).map { |n| { id: n.id, slug: n.slug, title: n.title, videoCount: n.items.size } }
      }
    end

    def show
      notebook = Notebook.friendly.find(params[:id])
      authorize! notebook, to: :show?
      render inertia: "notebooks/Show", props: {
        notebook: notebook_detail(notebook),
        availableVideos: Video.order(created_at: :desc).map { |v| { id: v.id, title: v.title } }
      }
    end

    def create
      notebook = Notebook.create!(title: params[:title].presence || "Untitled notebook", description: params[:description])
      redirect_to app_notebook_path(notebook)
    end

    def update
      notebook = Notebook.friendly.find(params[:id])
      authorize! notebook, to: :update?
      notebook.update!(params.permit(:title, :description))
      redirect_to app_notebook_path(notebook)
    end

    def destroy
      notebook = Notebook.friendly.find(params[:id])
      authorize! notebook, to: :destroy?
      notebook.destroy!
      redirect_to app_notebooks_path, notice: "Notebook deleted."
    end

    private

    def notebook_detail(notebook)
      items = notebook.items.includes(:video).to_a
      video_ids = items.map(&:video_id)
      progress = Progress.where(
        user: current_user, workspace: current_workspace, trackable_type: "Video", trackable_id: video_ids
      ).index_by(&:trackable_id)
      note_counts = Note.where(video_id: video_ids).group(:video_id).count

      {
        id: notebook.id, slug: notebook.slug, title: notebook.title, description: notebook.description,
        share: notebook.share && { id: notebook.share.id, token: notebook.share.token },
        progress: { completed: progress.values.count(&:completed?), total: video_ids.size },
        chapters: notebook.chapters.map { |ch| { id: ch.id, title: ch.title, position: ch.position } },
        items: items.map { |i|
          p = progress[i.video_id]
          {
            id: i.id, videoId: i.video_id, videoTitle: i.video.title,
            chapterId: i.notebook_chapter_id, position: i.position,
            durationSeconds: i.video.duration_seconds,
            noteCount: note_counts[i.video_id] || 0,
            resumeSeconds: p&.resume_seconds || 0,
            completed: p&.completed? || false
          }
        }
      }
    end
  end
end
