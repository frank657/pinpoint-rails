module App
  class ReviewController < BaseController
    # The daily review queue: cards due now whose note is in the current workspace. An
    # optional `theme` ("category:5", "tag:guard", "course:<id>") filters to one slice so a
    # user can drill a single topic (Phase 8 exit criteria).
    def index
      cards = due_cards.includes(:note).limit(50)
      render inertia: "review/Index", props: {
        cards: cards.map { |c|
          front, back = c.faces
          { id: c.id, noteTitle: c.note.title, front: front, back: back, state: c.state, template: c.card_template }
        },
        theme: params[:theme],
        themes: themes
      }
    end

    # Add a note to spaced-repetition review. Creates one card per cloze deletion, otherwise
    # a single basic card (Phase 8).
    def create
      note = Note.find(params[:note_id])
      ReviewCard.sync_for(note, current_user)
      redirect_back fallback_location: app_notes_path, notice: "Added to review."
    end

    # Grade a card (1=again … 4=easy) and reschedule via FSRS.
    def grade
      card = ReviewCard.where(user: current_user).find(params[:id])
      card.grade!(params[:rating])
      head :no_content
    end

    private

    def due_cards
      scope = ReviewCard.due
        .where(user: current_user)
        .joins(:note).where(notes: { workspace_id: current_workspace.id })
      apply_theme(scope).order(Arel.sql("due_at ASC NULLS FIRST"))
    end

    # Narrow the queue to a single category / tag / notebook when a theme is given.
    def apply_theme(scope)
      kind, value = params[:theme].to_s.split(":", 2)
      case kind
      when "category" then scope.where(notes: { category_id: value })
      when "tag"      then scope.joins(note: :tags).where(tags: { name: value })
      when "notebook"
        video_ids = Notebook.find(value).video_ids
        scope.where(notes: { video_id: video_ids })
      else scope
      end
    end

    # The theme choices offered in the UI: only slices that actually have due cards, so the
    # selector never points at an empty queue.
    def themes
      base = ReviewCard.due.where(user: current_user)
        .joins(:note).where(notes: { workspace_id: current_workspace.id })
      categories = Category.where(id: base.distinct.pluck(Arel.sql("notes.category_id")).compact)
        .order(:name).map { |c| { value: "category:#{c.id}", label: c.name } }
      notebooks = Notebook.where(id: base.joins(note: { video: :notebook_items }).distinct.pluck(Arel.sql("notebook_items.notebook_id")))
        .order(:title).map { |n| { value: "notebook:#{n.id}", label: n.title } }
      tags = Tag.where(id: base.joins(note: :tags).distinct.pluck(Arel.sql("tags.id")))
        .order(:name).map { |t| { value: "tag:#{t.name}", label: "##{t.name}" } }
      categories + notebooks + tags
    end
  end
end
