module App
  class PositionsController < BaseController
    def index
      render inertia: "positions/Index", props: {
        positions: Position.order(:name).map { |p| { id: p.id, name: p.name, category: p.category, dominance: p.dominance, noteCount: p.notes.size } },
        techniques: Technique.includes(:from_position, :to_position).order(:name).map { |t|
          { id: t.id, name: t.name, kind: t.kind, from: t.from_position&.name, to: t.to_position&.name }
        }
      }
    end

    def show
      position = Position.find(params[:id])
      authorize! position, to: :show?
      render inertia: "positions/Show", props: {
        position: { id: position.id, name: position.name, category: position.category, dominance: position.dominance },
        notes: position.notes.includes(:video).map { |n|
          { id: n.id, title: n.title, videoId: n.video_id, startSeconds: n.start_seconds }
        }
      }
    end

    def create
      Position.create!(params.permit(:name, :category, :dominance, :parent_id))
      redirect_to app_positions_path
    end

    def seed
      Bjj::SeedTaxonomy.call(current_workspace)
      redirect_to app_positions_path, notice: "BJJ taxonomy loaded."
    end
  end
end
