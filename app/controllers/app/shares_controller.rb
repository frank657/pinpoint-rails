module App
  class SharesController < BaseController
    SHAREABLE_TYPES = %w[Video Note Notebook].freeze

    # Read-only view of a shared object via its token (the recipient may be in another
    # workspace), with a "save to my workspace" (fork) action. The lookup uses without_tenant
    # so the recipient's own current workspace stays intact for forking.
    def create
      shareable = find_own_shareable(params[:shareable_type], params[:shareable_id])
      share = Share.find_or_initialize_by(shareable: shareable)
      share.shared_by ||= current_user
      share.visibility = params[:visibility].presence || "unlisted"
      share.save!
      redirect_back fallback_location: app_root_path, notice: "Share link ready."
    end

    def destroy
      share = Share.find(params[:id])
      authorize! share.shareable, to: :update?
      share.destroy!
      redirect_back fallback_location: app_root_path, notice: "Sharing turned off."
    end

    def show
      share = ActsAsTenant.without_tenant { Share.find_by!(token: params[:token]) }
      shareable = ActsAsTenant.without_tenant { share.shareable }
      render inertia: "shares/Show", props: {
        token: share.token,
        content: {
          type: shareable.class.name,
          title: content_title(shareable),
          summary: content_summary(shareable)
        }
      }
    end

    private

    def find_own_shareable(type, id)
      raise ActiveRecord::RecordNotFound unless SHAREABLE_TYPES.include?(type)

      type.constantize.find(id) # tenant-scoped: you can only share your own content
    end

    def content_title(obj)
      obj.try(:title) || obj.try(:name) || obj.class.name
    end

    def content_summary(obj)
      case obj
      when Notebook then "Notebook · #{ActsAsTenant.without_tenant { obj.items.size }} videos"
      when Video then "Video"
      when Note then "Note"
      end
    end
  end
end
