# Aliyun VOD adapter (ported from method-channel — see docs/decisions/0007).
#
# This namespace is a thin provider adapter over Aliyun's VOD API. It must NOT know about
# domain models (Vod, Video, …) — those live in app/models and app/services/vod_service.
require "aliyunsdkcore"

module AliVod
  # Identifies our callbacks in the shared Aliyun account (returned verbatim in webhooks).
  APP_TAG = "pinpoint".freeze

  def self.config
    Config.new
  end

  def self.client
    RPCClient.new access_key_id: config.access_key_id,
                  access_key_secret: config.access_key_secret,
                  endpoint: config.endpoint,
                  api_version: config.api_version
  end

  def self.video_ids(ids)
    ids.is_a?(Array) ? ids.join(",") : ids
  end

  # Packed into Aliyun "UserData" so the upload callback can be attributed back to us.
  def self.upload_callback_data(data = {})
    {
      "MessageCallback": { "CallbackURL": config.callback_url },
      "Extend": data.merge(app: APP_TAG)
    }.to_json
  end
end
