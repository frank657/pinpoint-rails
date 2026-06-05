# Attribution linking a forked copy back to its source (docs/decisions/0005). Global (spans
# workspaces) — NOT acts_as_tenant. Creates no ongoing data coupling.
class Fork < ApplicationRecord
  belongs_to :source_workspace, class_name: "Workspace", optional: true
  belongs_to :target_workspace, class_name: "Workspace"
  belongs_to :forked_by, class_name: "User", optional: true

  def source = source_type.constantize.find_by(id: source_id)
  def target = target_type.constantize.find_by(id: target_id)
end
