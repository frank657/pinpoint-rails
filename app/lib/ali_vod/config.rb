module AliVod
  # Reads Aliyun VOD settings from encrypted credentials (see docs/SETUP_CREDENTIALS.md).
  class Config
    attr_reader :access_key_id, :access_key_secret, :endpoint, :api_version,
                :video_template, :root_url, :storage_location, :callback_url

    def initialize
      aliyun = Rails.application.credentials.aliyun

      @access_key_id     = aliyun.access_key_id
      @access_key_secret = aliyun.access_key_secret

      @endpoint         = aliyun.vod.endpoint
      @api_version      = aliyun.vod.api_version
      @storage_location = aliyun.vod.storage_location
      @video_template   = aliyun.vod.video_template

      @root_url     = AppConfig.host_backend
      @callback_url = "#{@root_url}/webhooks/aliyun/vod"
    end
  end
end
