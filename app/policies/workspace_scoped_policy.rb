# Base policy for workspace-scoped content/taxonomy. acts_as_tenant already restricts queries
# to the current workspace; this is defense-in-depth membership for record-level actions.
class WorkspaceScopedPolicy < ApplicationPolicy
  def show?    = membership?
  def create?  = true
  def update?  = membership?
  def destroy? = membership?

  private

  def membership?
    user&.member_of?(record.workspace)
  end
end
