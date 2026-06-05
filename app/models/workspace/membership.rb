# Join between a User (login identity) and a Workspace (tenant). Roles enable future
# multi-member workspaces (docs/decisions/0002). Table: workspace_memberships.
class Workspace::Membership < ApplicationRecord
  self.table_name = "workspace_memberships"

  belongs_to :user
  belongs_to :workspace

  enum :role, { owner: 0, member: 1 }

  validates :user_id, uniqueness: { scope: :workspace_id }
end
