module App
  module Curriculums
    class ItemsController < App::BaseController
      def create
        curriculum.items.create!(course_id: params[:course_id], position: next_position)
        redirect_to app_curriculum_path(curriculum)
      end

      def destroy
        curriculum.items.find(params[:id]).destroy!
        redirect_to app_curriculum_path(curriculum)
      end

      def reorder
        Array(params[:ids]).each_with_index do |id, i|
          curriculum.items.where(id: id).update_all(position: i)
        end
        head :ok
      end

      private

      def curriculum
        @curriculum ||= Curriculum.friendly.find(params[:curriculum_id]).tap { |c| authorize! c, to: :update? }
      end

      def next_position
        (curriculum.items.maximum(:position) || -1) + 1
      end
    end
  end
end
