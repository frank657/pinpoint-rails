FactoryBot.define do
  factory :workspace do
    sequence(:name) { |n| "Workspace #{n}" }
  end
end
