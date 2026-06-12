FactoryBot.define do
  factory :notebook do
    workspace
    sequence(:title) { |n| "Notebook #{n}" }
  end
end
