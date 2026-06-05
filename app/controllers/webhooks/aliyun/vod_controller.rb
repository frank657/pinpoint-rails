module Webhooks
  module Aliyun
    # Receives Aliyun VOD lifecycle callbacks (ported from method-channel, ADR 0007).
    # Flips the Vod status: FileUploadComplete → uploaded, TranscodeComplete → ready.
    # Vod is shared media (not tenant-scoped), so no tenant context is needed here.
    class VodController < Webhooks::BaseController
      before_action :authenticate_callback, :set_options

      def verify
        return head(:ok) unless pinpoint?

        case @event
        when "FileUploadComplete" then file_upload_complete
        when "TranscodeComplete"  then transcode_complete
        end

        head :ok
      end

      private

      def file_upload_complete
        Vod.find_by(key: @video_id)&.uploaded!
      end

      def transcode_complete
        vod = Vod.find_by(key: @video_id)
        return unless vod

        vod.update!(status: :ready, duration: @info&.dig(0, "Duration"))
        vod.attach_cover_image_from_provider
        enqueue_transcription(vod)
      end

      # Kick off ASR for every uploaded Video that references this now-ready Vod. Videos can
      # span workspaces (a forked video shares the Vod by reference), so we pass each one's
      # workspace through and let the job re-enter that tenant (docs/decisions/0005).
      def enqueue_transcription(vod)
        ActsAsTenant.without_tenant do
          Video.where(vod_id: vod.id, source: Video.sources[:upload]).find_each do |video|
            TranscribeJob.perform_later(video.id, video.workspace_id)
          end
        end
      end

      def set_options
        @event    = params["EventType"]
        @video_id = params["VideoId"]
        @metadata = JSON.parse(params["Extend"].presence || "{}")
        @app      = @metadata["app"]
        @info     = params["StreamInfos"]
      end

      def authenticate_callback
        return if valid_signature?

        head :forbidden
      end

      def valid_signature?
        auth = Rails.application.credentials.dig(:aliyun, :vod, :callback_auth)
        expected = Digest::MD5.hexdigest([ request.original_url, request.headers["X-VOD-TIMESTAMP"], auth ].join("|"))
        ActiveSupport::SecurityUtils.secure_compare(request.headers["X-VOD-SIGNATURE"].to_s, expected)
      end

      def pinpoint? = @app == AliVod::APP_TAG
    end
  end
end
