module App
  module Notebooks
    class ItemsController < App::BaseController
      def create
        notebook.items.create!(
          video_id:           params[:video_id],
          notebook_chapter_id: params[:notebook_chapter_id].presence,
          position:           next_position
        )
        redirect_to app_notebook_path(notebook)
      end

      def update
        notebook.items.find(params[:id]).update!(params.permit(:notebook_chapter_id, :position))
        redirect_to app_notebook_path(notebook)
      end

      def destroy
        notebook.items.find(params[:id]).destroy!
        redirect_to app_notebook_path(notebook)
      end

      # Drag-reorder (axios): rewrite positions from the given id order.
      def reorder
        Array(params[:ids]).each_with_index do |id, i|
          notebook.items.where(id: id).update_all(position: i)
        end
        head :ok
      end

      private

      def notebook
        @notebook ||= Notebook.friendly.find(params[:notebook_id]).tap { |n| authorize! n, to: :update? }
      end

      def next_position
        (notebook.items.maximum(:position) || -1) + 1
      end
    end
  end
end
