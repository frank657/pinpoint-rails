module App
  module Courses
    class ItemsController < App::BaseController
      def create
        course.items.create!(video_id: params[:video_id], position: next_position)
        redirect_to app_course_path(course)
      end

      def update
        course.items.find(params[:id]).update!(params.permit(:course_chapter_id, :position))
        redirect_to app_course_path(course)
      end

      def destroy
        course.items.find(params[:id]).destroy!
        redirect_to app_course_path(course)
      end

      # Drag-reorder (axios): rewrite positions from the given id order.
      def reorder
        Array(params[:ids]).each_with_index do |id, i|
          course.items.where(id: id).update_all(position: i)
        end
        head :ok
      end

      private

      def course
        @course ||= Course.friendly.find(params[:course_id]).tap { |c| authorize! c, to: :update? }
      end

      def next_position
        (course.items.maximum(:position) || -1) + 1
      end
    end
  end
end
