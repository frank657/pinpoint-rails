module App
  class CategoriesController < BaseController
    def index
      render json: Category.order(:name).map { |c| { id: c.id, name: c.name } }
    end

    def create
      category = Category.create!(name: params[:name])
      redirect_back fallback_location: app_notes_path, notice: "Category created.",
                    inertia: { category: { id: category.id, name: category.name } }
    end

    def update
      category = Category.find(params[:id])
      authorize! category, to: :update?
      category.update!(name: params[:name])
      redirect_back fallback_location: app_notes_path
    end

    def destroy
      category = Category.find(params[:id])
      authorize! category, to: :destroy?
      category.destroy!
      redirect_back fallback_location: app_notes_path
    end
  end
end
