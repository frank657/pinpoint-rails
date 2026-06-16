module App
  class SearchController < BaseController
    # Full-text search across notes and videos; results deep-link to the moment / video.
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

    def empty = { notes: [], videos: [] }

    def results_for(q)
      {
        notes: Note.search(q).limit(20).map { |n|
          { id: n.id, title: n.title, videoId: n.video_id, startSeconds: n.start_seconds }
        },
        videos: video_results(q).map { |v|
          { id: v.id, title: v.title, source: v.source, poster: video_poster(v) }
        }
      }
    end

    # Videos matching by title, tag, or featured athlete. Tag/athlete ids are gathered separately
    # (the polymorphic string taggable_id can't be SQL-joined to videos.id) then unioned.
    def video_results(q)
      like = "%#{Video.sanitize_sql_like(q)}%"
      ids  = Video.where("title ILIKE ?", like).ids
      ids += Tagging.joins(:tag).where(taggable_type: "Video").where("tags.name ILIKE ?", like).pluck(:taggable_id).map(&:to_i)
      ids += Video.joins(:athletes).where("athletes.name ILIKE ?", like).ids
      Video.where(id: ids.uniq).order(created_at: :desc).limit(20)
    end
  end
end
