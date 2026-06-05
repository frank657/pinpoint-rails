FactoryBot.define do
  factory :workspace_membership, class: "Workspace::Membership" do
    association :user
    association :workspace
    role { :owner }
  end
end
