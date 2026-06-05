# Base policy. `user` (the signed-in User) is the authorization context, supplied by the
# controller via `authorize :user, through: :current_user`. Default-deny: subclasses opt
# specific rules in. See docs/decisions/0008.
class ApplicationPolicy < ActionPolicy::Base
  authorize :user

  def index?   = false
  def show?    = false
  def create?  = false
  def new?     = create?
  def update?  = false
  def edit?    = update?
  def destroy? = false
  def manage?  = false
end
