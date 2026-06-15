module App
  # Tag management surface: list (with usage counts) + create / rename / merge / delete.
  # Tags are workspace-scoped (acts_as_tenant) and applied polymorphically to content
  # (iteration 0006a).
  class TagsController < BaseController
    def index
      render inertia: "tags/Index", props: {
        tags: Tag.order(:name).map { |t| tag_json(t) }
      }
    end

    def create
      Tag.create!(name: params[:name])
      redirect_to app_tags_path, notice: "Tag created."
    end

    def update
      tag = Tag.find(params[:id])
      authorize! tag, to: :update?
      tag.update!(name: params[:name])
      redirect_to app_tags_path, notice: "Tag renamed."
    end

    def destroy
      tag = Tag.find(params[:id])
      authorize! tag, to: :destroy?
      tag.destroy!
      redirect_to app_tags_path, notice: "Tag deleted."
    end

    # Merge this tag (params[:id]) into another (params[:target_id]), re-pointing its taggings.
    def merge
      source = Tag.find(params[:id])
      target = Tag.find(params[:target_id])
      authorize! source, to: :update?
      source.merge_into!(target)
      redirect_to app_tags_path, notice: "Tags merged."
    end

    private

    def tag_json(tag)
      { id: tag.id, name: tag.name, count: tag.usage_count }
    end
  end
end
