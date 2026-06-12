module Admin
  class DashboardController < BaseController
    def index
      render inertia: "admin/Dashboard", props: {
        stats: {
          users: User.count,
          workspaces: Workspace.count,
          videos: Video.count,
          vods: Vod.count,
          notes: Note.count,
          notebooks: Notebook.count
        }
      }
    end
  end
end
