module Admin
  class WorkspacesController < BaseController
    def index
      render inertia: "admin/Workspaces", props: {
        workspaces: Workspace.order(created_at: :desc).limit(100).map { |w|
          { id: w.id, name: w.name, slug: w.slug, members: w.members.count, owner: w.owner&.email, createdAt: w.created_at.iso8601 }
        }
      }
    end
  end
end
