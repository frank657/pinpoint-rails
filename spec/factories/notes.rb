FactoryBot.define do
  factory :note do
    note_type { :timestamp }
    title { "A note" }
    start_seconds { 12.5 }
    association :video
    workspace { video&.workspace || association(:workspace) }

    trait :rich_text do
      note_type { :rich_text }
      video { nil }
      start_seconds { nil }
      title { "Big note" }
    end

    trait :range do
      end_seconds { 30.0 }
    end
  end
end
