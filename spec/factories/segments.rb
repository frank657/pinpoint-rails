FactoryBot.define do
  factory :segment do
    association :video
    workspace { video&.workspace || association(:workspace) }
    title { "Intro" }
    start_seconds { 5.0 }
  end
end
