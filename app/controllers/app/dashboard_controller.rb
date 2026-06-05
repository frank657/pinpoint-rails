module App
  class DashboardController < BaseController
    def index
      recents = Progress.in_progress
        .where(user: current_user, workspace: current_workspace, trackable_type: "Video")
        .order(last_viewed_at: :desc).limit(6)
      videos = Video.where(id: recents.map(&:trackable_id)).index_by(&:id)

      render inertia: "Dashboard", props: {
        continueWatching: recents.filter_map { |p|
          video = videos[p.trackable_id]
          { id: video.id, title: video.title, resumeSeconds: p.resume_seconds } if video
        }
      }
    end
  end
end
