# Deep-copies a content subtree in the background for large forks (docs/decisions/0005).
class ForkJob < ApplicationJob
  queue_as :default

  def perform(source, target_workspace:, forked_by: nil)
    ForkService.call(source, target_workspace: target_workspace, forked_by: forked_by)
  end
end
