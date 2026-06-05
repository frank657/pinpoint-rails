# Stubs for the Aliyun VOD provider so specs never hit the network (docs/decisions/0007).
module AliyunStubs
  # Makes Vod creation (after_create → provisioning) and deletion no-ops with fake data.
  def stub_aliyun!(video_id: "VOD#{SecureRandom.hex(6)}", file_name: "video.mp4")
    upload_data = {
      video_id: video_id,
      upload_address: Base64.strict_encode64({
        Endpoint: "oss-cn-shanghai.aliyuncs.com", Bucket: "pinpoint-test", FileName: file_name
      }.to_json),
      upload_auth: Base64.strict_encode64({
        AccessKeyId: "STS.ak", AccessKeySecret: "sk", SecurityToken: "tok",
        ExpireUTCTime: 2.hours.from_now.utc.iso8601
      }.to_json)
    }
    allow(VodService::Aliyun::Uploader).to receive(:create).and_return(upload_data)
    allow(AliVod::Request).to receive(:post).and_return({})
    upload_data
  end
end

RSpec.configure do |config|
  config.include AliyunStubs
end
