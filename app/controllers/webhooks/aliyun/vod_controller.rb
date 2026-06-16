module Webhooks
  module Aliyun
    # Receives Aliyun VOD lifecycle callbacks (ported from method-channel, ADR 0007).
    # Flips the Vod status: FileUploadComplete → uploaded, TranscodeComplete → ready.
    # Vod is shared media (not tenant-scoped), so no tenant context is needed here.
    class VodController < Webhooks::BaseController
      before_action :authenticate_callback, :set_options

      def verify
        Rails.logger.info("[Aliyun VOD webhook] event=#{@event} video_id=#{@video_id} app=#{@app.inspect}")

        unless pinpoint?
          Rails.logger.info("[Aliyun VOD webhook] ignored — app tag #{@app.inspect} != #{AliVod::APP_TAG.inspect}")
          return head(:ok)
        end

        case @event
        when "FileUploadComplete" then file_upload_complete
        when "TranscodeComplete"  then transcode_complete
        else Rails.logger.info("[Aliyun VOD webhook] no handler for event #{@event.inspect}")
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

        Rails.logger.warn(
          "[Aliyun VOD webhook] signature mismatch — url=#{request.original_url} " \
          "ts=#{request.headers['X-VOD-TIMESTAMP'].inspect} sig=#{request.headers['X-VOD-SIGNATURE'].inspect}"
        )
        head :forbidden
      end

      # Aliyun signs over the CallbackURL it was given. Behind a proxy/tunnel (cloudflared),
      # request.original_url is reconstructed with the forwarded scheme (https), which differs
      # from the registered callback URL (http) — so verify against the registered URL too.
      def valid_signature?
        auth = Rails.application.credentials.dig(:aliyun, :vod, :callback_auth)
        ts   = request.headers["X-VOD-TIMESTAMP"]
        sig  = request.headers["X-VOD-SIGNATURE"].to_s

        candidate_urls = [ AliVod::Config.new.callback_url, request.original_url ].uniq
        candidate_urls.any? do |url|
          expected = Digest::MD5.hexdigest([ url, ts, auth ].join("|"))
          ActiveSupport::SecurityUtils.secure_compare(sig, expected)
        end
      end

      def pinpoint? = @app == AliVod::APP_TAG
    end
  end
end
