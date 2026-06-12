module App
  class NotesController < BaseController
    def index
      notes = filtered_notes
      render inertia: "notes/Index", props: {
        notes: notes.includes(:category, :tags, :rich_text_body).map { |n| note_json(n) },
        categories: Category.order(:name).map { |c| { id: c.id, name: c.name } },
        tags: Tag.order(:name).pluck(:name),
        filters: { categoryId: params[:category_id], tag: params[:tag], q: params[:q] }
      }
    end

    def new
      render inertia: "notes/New", props: {
        categories: Category.order(:name).map { |c| { id: c.id, name: c.name } },
        tags: Tag.order(:name).pluck(:name)
      }
    end

    def create
      note = Note.new(note_attrs)
      note.created_by = current_user
      note.tags = Tag.for_names(tag_names) if tag_names
      assign_taxonomy(note)
      note.save!
      respond_after(note)
    end

    def update
      note = Note.find(params[:id])
      authorize! note, to: :update?
      note.update!(note_attrs)
      note.tags = Tag.for_names(tag_names) if tag_names
      assign_taxonomy(note)
      respond_after(note)
    end

    def destroy
      note = Note.find(params[:id])
      authorize! note, to: :destroy?
      note.destroy!
      redirect_back fallback_location: app_notes_path, notice: "Note deleted."
    end

    private

    def filtered_notes
      notes = Note.all
      notes = notes.where(category_id: params[:category_id]) if params[:category_id].present?
      notes = notes.joins(:tags).where(tags: { name: params[:tag] }) if params[:tag].present?
      notes = notes.search(params[:q]) if params[:q].present?
      notes.order(created_at: :desc)
    end

    def respond_after(note)
      if note.video_id
        redirect_to app_video_path(note.video_id)
      else
        redirect_to app_notes_path
      end
    end

    def note_attrs
      params.permit(:note_type, :video_id, :category_id, :title, :start_seconds, :end_seconds, :body)
    end

    # Curated taxonomy (Phase 10) — separate from free tags.
    def assign_taxonomy(note)
      note.positions = Position.where(id: params[:position_ids]) if params.key?(:position_ids)
      note.techniques = Technique.where(id: params[:technique_ids]) if params.key?(:technique_ids)
    end

    def tag_names
      return nil unless params.key?(:tag_names)

      raw = params[:tag_names]
      raw.is_a?(Array) ? raw : raw.to_s.split(",")
    end
  end
end
