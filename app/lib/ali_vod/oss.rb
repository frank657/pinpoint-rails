module AliVod
  # Wraps the Aliyun OSS client using the STS credentials returned by CreateUploadVideo.
  # (Used for any server-side OSS work; the browser uploads directly with the same creds.)
  class Oss
    attr_reader :client, :bucket

    def initialize(upload_address, upload_auth)
      @bucket = upload_address[:bucket]
      @client = Aliyun::OSS::Client.new(
        endpoint: upload_address[:endpoint],
        sts_token: upload_auth[:security_token],
        access_key_id: upload_auth[:access_key_id],
        access_key_secret: upload_auth[:access_key_secret],
        open_timeout: 86_400 * 7,
        read_timeout: 86_400 * 7
      )
    end
  end
end
