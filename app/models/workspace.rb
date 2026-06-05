# A Workspace is the tenancy boundary — one user's "account for a topic" (docs/decisions/0002).
# It is the acts_as_tenant tenant, so it is NOT itself tenant-scoped.
#
# Acts as a namespace for its nested models (Workspace::Membership, …). Because Workspace
# is itself a table, nested models set their own `table_name` explicitly rather than using
# table_name_prefix (which would also rewrite Workspace's own table).
class Workspace < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :workspace_memberships, class_name: "Workspace::Membership", dependent: :destroy
  has_many :members, through: :workspace_memberships, source: :user

  validates :name, presence: true

  def owner
    workspace_memberships.find_by(role: :owner)&.user
  end
end
