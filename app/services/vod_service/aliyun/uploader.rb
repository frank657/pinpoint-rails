# Provisions Aliyun VOD upload credentials and decodes the Base64 address/auth blobs.
class VodService::Aliyun::Uploader
  attr_reader :video_id

  def self.create(data = {})
    AliVod::Video.create_upload_data(**data)
  end

  def initialize(video_id, upload_data = nil)
    @video_id    = video_id
    @upload_data = upload_data
  end

  def upload_data
    @upload_data ||= ::AliVod::Video.new(@video_id)&.upload_data
  end

  def decrypted_upload_address
    return unless upload_data[:upload_address]

    JSON.parse(Base64.decode64(upload_data[:upload_address]))&.keys_to_snake_case
  end

  def decrypted_upload_auth
    return unless upload_data[:upload_auth]

    JSON.parse(Base64.decode64(upload_data[:upload_auth]))&.keys_to_snake_case
  end
end
