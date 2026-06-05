module App
  class FoldersController < BaseController
    def index
      render inertia: "folders/Index", props: {
        folders: Folder.order(:position, :name).map { |f| { id: f.id, name: f.name, parentId: f.parent_id, position: f.position } }
      }
    end

    def create
      Folder.create!(name: params[:name].presence || "New folder", parent_id: params[:parent_id])
      redirect_to app_folders_path
    end

    def update
      folder = Folder.find(params[:id])
      authorize! folder, to: :update?
      folder.update!(params.permit(:name, :parent_id, :position))
      redirect_to app_folders_path
    end

    def destroy
      folder = Folder.find(params[:id])
      authorize! folder, to: :destroy?
      folder.destroy!
      redirect_to app_folders_path
    end
  end
end
