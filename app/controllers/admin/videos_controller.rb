module Admin
  class VideosController < BaseController
    def index
      render inertia: "admin/Videos", props: {
        videos: Video.includes(:vod, :workspace).order(created_at: :desc).limit(100).map { |v|
          {
            id: v.id, title: v.title, source: v.source, workspace: v.workspace.name,
            vodStatus: v.vod&.status, vodKey: v.vod&.key, createdAt: v.created_at.iso8601
          }
        }
      }
    end
  end
end
