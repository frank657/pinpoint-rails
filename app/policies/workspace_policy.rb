# A user may act on a workspace only if they are a member of it (docs/decisions/0002).
class WorkspacePolicy < ApplicationPolicy
  def manage?
    user.member_of?(record)
  end

  alias_rule :show?, :update?, :destroy?, to: :manage?

  # Scope a relation to the workspaces the user belongs to.
  relation_scope do |relation|
    relation.joins(:workspace_memberships).where(workspace_memberships: { user_id: user.id })
  end
end
