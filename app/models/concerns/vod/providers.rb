# Aliyun-specific behaviour for Vod, kept out of the model body (ported from method-channel).
module Vod::Providers
  extend ActiveSupport::Concern

  def aliyun_video
    @aliyun_video ||= VodService::Aliyun::Video.new(self) if aliyun?
  end

  def aliyun_uploader
    @aliyun_uploader ||= VodService::Aliyun::Uploader.new(key) if aliyun?
  end

  def update_aliyun_vod_info
    return unless aliyun?

    data = [ { "VideoId": key, "Tags": Rails.env, "FileName": filename, "Title": title } ]
    ::AliVod::Request.post(:update_video_info, { "UpdateContent": data.to_json })
  end

  def uploaded_to_provider?
    return true if uploaded? || ready?

    provider_uploaded?
  end

  private

  def destroy_vod_object
    aliyun_video.destroy if aliyun?
  end

  # after_create: ask Aliyun to provision an upload, then store the returned identifiers.
  def create_aliyun_upload_data
    return unless aliyun?

    upload_data = VodService::Aliyun::Uploader.create(title:, file_name: filename)
    @aliyun_uploader = VodService::Aliyun::Uploader.new(upload_data[:video_id], upload_data)
    update!(
      key: @aliyun_uploader.video_id,
      filename: @aliyun_uploader.decrypted_upload_address[:file_name],
      upload_expires_at: Time.iso8601(@aliyun_uploader.decrypted_upload_auth[:expire_utc_time])
    )
  end

  def provider_uploaded?
    case provider
    when "aliyun" then aliyun_video&.uploaded? || false
    else false
    end
  rescue StandardError => e
    Rails.logger.warn("[Vod##{id}] provider_uploaded? failed: #{e.class} #{e.message}")
    false
  end
end
