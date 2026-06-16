module App
  # Category management surface: list (with usage counts) + create / rename / merge / delete.
  class CategoriesController < BaseController
    def index
      render inertia: "categories/Index", props: {
        categories: Category.order(:name).map { |c| { id: c.id, name: c.name, count: c.usage_count } }
      }
    end

    def create
      Category.create!(name: params[:name])
      redirect_to app_categories_path, notice: "Category created."
    end

    def update
      category = Category.find(params[:id])
      authorize! category, to: :update?
      category.update!(name: params[:name])
      redirect_to app_categories_path, notice: "Category renamed."
    end

    def destroy
      category = Category.find(params[:id])
      authorize! category, to: :destroy?
      category.destroy!
      redirect_to app_categories_path, notice: "Category deleted."
    end

    # Merge this category (params[:id]) into another (params[:target_id]), re-filing its notes.
    def merge
      source = Category.find(params[:id])
      target = Category.find(params[:target_id])
      authorize! source, to: :update?
      source.merge_into!(target)
      redirect_to app_categories_path, notice: "Categories merged."
    end
  end
end
