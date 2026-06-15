module App
  class SearchController < BaseController
    # Full-text search across notes; results deep-link to the moment.
    def index
      q = params[:q].to_s
      render inertia: "Search", props: { q: q, results: q.present? ? results_for(q) : empty }
    end

    # Lightweight JSON endpoint for the spotlight modal — no Inertia overhead.
    def query
      q = params[:q].to_s.strip
      render json: q.present? ? results_for(q) : empty
    end

    private

    def empty = { notes: [] }

    def results_for(q)
      {
        notes: Note.search(q).limit(20).map { |n|
          { id: n.id, title: n.title, videoId: n.video_id, startSeconds: n.start_seconds }
        }
      }
    end
  end
end
