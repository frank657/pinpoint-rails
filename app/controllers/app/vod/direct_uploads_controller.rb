module App
  module Vod
    # Step 1 of the direct-upload flow: provision an Aliyun VOD upload and return STS
    # credentials. The Video record is NOT created here — only the Vod (shared media).
    # The client uploads directly to OSS, then polls #status until "uploaded" or "ready",
    # then calls POST /videos with the signed_id to create the Video. (ADR 0007)
    class DirectUploadsController < App::BaseController
      def create
        vod = ::Vod.create!(
          provider:    :aliyun,
          title:       params[:title].presence,
          filename:    params[:filename].presence || "video.mp4",
          uploaded_by: current_user
        )
        data = vod.aliyun_uploader.upload_data
        render json: {
          signedId:      vod.signed_id(purpose: :vod_upload, expires_in: 2.hours),
          uploadAddress: data[:upload_address],
          uploadAuth:    data[:upload_auth]
        }, status: :created
      end

      # Belt-and-suspenders: reconcile the Vod status against Aliyun on every poll so
      # the client unblocks even when the webhook can't reach the server (e.g. dev).
      def status
        vod = ::Vod.find_signed!(params[:signed_id], purpose: :vod_upload)
        raise ActiveRecord::RecordNotFound unless vod.uploaded_by == current_user

        vod.sync_from_provider! if vod.uploading?
        render json: { status: vod.status, ready: vod.uploaded_to_provider? }
      end
    end
  end
end
