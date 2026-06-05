FactoryBot.define do
  # NOTE: creating a :vod triggers Aliyun provisioning — call `stub_aliyun!` first.
  factory :vod do
    provider { :aliyun }
  end
end
