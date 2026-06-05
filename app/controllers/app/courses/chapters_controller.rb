module App
  module Courses
    class ChaptersController < App::BaseController
      def create
        course.chapters.create!(title: params[:title].presence || "New chapter", position: next_position)
        redirect_to app_course_path(course)
      end

      def update
        course.chapters.find(params[:id]).update!(params.permit(:title, :position))
        redirect_to app_course_path(course)
      end

      def destroy
        course.chapters.find(params[:id]).destroy!
        redirect_to app_course_path(course)
      end

      private

      def course
        @course ||= Course.friendly.find(params[:course_id]).tap { |c| authorize! c, to: :update? }
      end

      def next_position
        (course.chapters.maximum(:position) || -1) + 1
      end
    end
  end
end
