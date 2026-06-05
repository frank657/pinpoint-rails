class User < ApplicationRecord
  # Session-based Devise (no JWT — see docs/decisions/0001).
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :workspace_memberships, class_name: "Workspace::Membership", dependent: :destroy
  has_many :workspaces, through: :workspace_memberships

  after_create :create_default_workspace

  # `admin?` comes from the boolean column and gates admin.<domain> (docs/decisions/0006).

  def member_of?(workspace)
    workspace_memberships.exists?(workspace_id: workspace.id)
  end

  private

  # Every user starts with one workspace so they always have a tenant (docs/decisions/0002).
  def create_default_workspace
    workspace = Workspace.create!(name: "Personal")
    workspace_memberships.create!(workspace: workspace, role: :owner)
  end
end
