module App
  class SegmentsController < BaseController
    def create
      segment = Segment.new(segment_attrs.except(:position))
      segment.position = params[:position].presence || next_position(segment.video_id)
      segment.save!
      redirect_to app_video_path(segment.video_id)
    end

    def update
      segment = Segment.find(params[:id])
      authorize! segment, to: :update?
      segment.update!(segment_attrs)
      redirect_to app_video_path(segment.video_id)
    end

    def destroy
      segment = Segment.find(params[:id])
      authorize! segment, to: :destroy?
      video_id = segment.video_id
      segment.destroy!
      redirect_to app_video_path(video_id)
    end

    private

    def next_position(video_id)
      (Segment.where(video_id: video_id).maximum(:position) || -1) + 1
    end

    def segment_attrs
      params.permit(:video_id, :title, :start_seconds, :end_seconds, :position)
    end
  end
end
