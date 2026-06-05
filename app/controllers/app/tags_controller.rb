module App
  class TagsController < BaseController
    # Autocomplete: GET /tags?q=clo
    def index
      tags = Tag.order(:name)
      tags = tags.where("name ILIKE ?", "#{params[:q]}%") if params[:q].present?
      render json: tags.limit(20).pluck(:name)
    end
  end
end
