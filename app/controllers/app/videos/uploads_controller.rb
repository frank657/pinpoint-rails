module App
  module Videos
    # JSON endpoint: provisions an Aliyun VOD upload (creates the Vod + Video) and returns
    # the credentials the browser uses to upload directly to OSS (docs/roadmap/phases/phase-2).
    class UploadsController < App::BaseController
      def create
        vod = Vod.create!(
          provider: :aliyun,
          title: upload_params[:title],
          filename: upload_params[:filename],
          uploaded_by: current_user
        )
        video = Video.create!(
          source: :upload,
          vod: vod,
          title: upload_params[:title].presence || upload_params[:filename],
          uploaded_by: current_user
        )

        data = vod.aliyun_uploader.upload_data
        render json: {
          videoId: video.id,
          signedId: vod.signed_id(purpose: :vod_upload, expires_in: 2.hours),
          uploadAddress: data[:upload_address],
          uploadAuth: data[:upload_auth]
        }, status: :created
      end

      private

      def upload_params
        params.permit(:filename, :title)
      end
    end
  end
end
