# Ported from method-channel (see docs/decisions/0007).
#
# Patches ActiveStorage's Aliyun service so private URLs are signed with the right
# content-disposition/filename handling. Loaded lazily via to_prepare so it only kicks in
# once the activestorage-aliyun service class is available.
Rails.application.config.to_prepare do
  require "active_storage/service/aliyun_service"

  module ActiveStorage
    class Service::AliyunService < Service
      private

      def private_url(key, expires_in: 60, filename: nil, content_type: nil, disposition: nil, params: {}, **)
        params.delete("response-content-type")

        filekey = path_for(key)

        if filename
          filename = ActiveStorage::Filename.wrap(filename)
          params["response-content-disposition"] = content_disposition_with(type: disposition, filename: filename)
        end

        object_url(filekey, sign: true, expires_in: expires_in, params: params)
      end
    end
  end
end
