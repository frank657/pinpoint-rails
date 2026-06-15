FactoryBot.define do
  factory :athlete do
    workspace
    sequence(:name) { |n| "Athlete #{n}" }
  end
end
