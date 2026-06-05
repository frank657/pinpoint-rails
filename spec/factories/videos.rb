FactoryBot.define do
  factory :video do
    workspace
    title { "My Video" }
    source { :youtube }
    sequence(:youtube_id) { |n| format("ytvid%05d", n) }

    # Requires stub_aliyun! (the associated :vod provisions on create).
    trait :upload do
      source { :upload }
      youtube_id { nil }
      association :vod
    end
  end
end
