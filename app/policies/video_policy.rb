# acts_as_tenant already restricts Video queries to the current workspace; this is the
# defense-in-depth membership check for record-level actions (docs/decisions/0008).
class VideoPolicy < ApplicationPolicy
  def show?    = membership?
  def update?  = membership?
  def destroy? = membership?

  alias_rule :status?, to: :show?

  private

  def membership?
    user&.member_of?(record.workspace)
  end
end
