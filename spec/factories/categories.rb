FactoryBot.define do
  factory :category do
    workspace
    sequence(:name) { |n| "Category #{n}" }
  end
end
