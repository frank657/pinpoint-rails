FactoryBot.define do
  # NOTE: creating a :vod triggers Aliyun provisioning — call `stub_aliyun!` first.
  factory :vod do
    provider { :aliyun }

    trait :uploaded do
      status { :uploaded }
      sequence(:key) { |n| "vod-key-#{n}" }
      uploaded_at { Time.current }
    end

    trait :ready do
      status { :ready }
      sequence(:key) { |n| "vod-key-#{n}" }
      uploaded_at { 5.minutes.ago }
      ready_at { Time.current }
      duration { 120.0 }
    end
  end
end
