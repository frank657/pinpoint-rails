module App
  class SearchController < BaseController
    # Full-text search across transcript lines and notes; results deep-link to the moment.
    def index
      q = params[:q].to_s
      render inertia: "Search", props: { q: q, results: q.present? ? results_for(q) : empty }
    end

    private

    def empty = { transcript: [], notes: [] }

    def results_for(query)
      {
        transcript: TranscriptLine.search(query).includes(:video).limit(30).map { |l|
          { videoId: l.video_id, videoTitle: l.video.title, startSeconds: l.start_seconds, text: l.text }
        },
        notes: Note.search(query).limit(30).map { |n|
          { id: n.id, title: n.title, videoId: n.video_id, startSeconds: n.start_seconds }
        }
      }
    end
  end
end
