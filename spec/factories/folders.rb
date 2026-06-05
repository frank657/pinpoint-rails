FactoryBot.define do
  factory :folder do
    workspace
    sequence(:name) { |n| "Folder #{n}" }
  end
end
