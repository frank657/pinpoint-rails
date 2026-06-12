module App
  module Notebooks
    class ChaptersController < App::BaseController
      def create
        notebook.chapters.create!(title: params[:title].presence || "New chapter", position: next_position)
        redirect_to app_notebook_path(notebook)
      end

      def update
        notebook.chapters.find(params[:id]).update!(params.permit(:title, :position))
        redirect_to app_notebook_path(notebook)
      end

      def destroy
        notebook.chapters.find(params[:id]).destroy!
        redirect_to app_notebook_path(notebook)
      end

      private

      def notebook
        @notebook ||= Notebook.friendly.find(params[:notebook_id]).tap { |n| authorize! n, to: :update? }
      end

      def next_position
        (notebook.chapters.maximum(:position) || -1) + 1
      end
    end
  end
end
