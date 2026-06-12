module App
  class SearchController < BaseController
    # Full-text search across transcript lines and notes; results deep-link to the moment.
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

    def empty = { transcript: [], notes: [] }

    def results_for(q)
      {
        transcript: TranscriptLine.search(q).includes(:video).limit(20).map { |l|
          { videoId: l.video_id, videoTitle: l.video.title, startSeconds: l.start_seconds, text: l.text }
        },
        notes: Note.search(q).limit(20).map { |n|
          { id: n.id, title: n.title, videoId: n.video_id, startSeconds: n.start_seconds }
        }
      }
    end
  end
end
