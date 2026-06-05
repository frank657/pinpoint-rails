FactoryBot.define do
  factory :course do
    workspace
    sequence(:title) { |n| "Course #{n}" }
  end
end
