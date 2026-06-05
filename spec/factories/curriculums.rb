FactoryBot.define do
  factory :curriculum do
    workspace
    sequence(:title) { |n| "Curriculum #{n}" }
  end
end
