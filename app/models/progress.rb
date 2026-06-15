# Per-user progress on a trackable (Video). Axis 3 (docs/decisions/0004):
# private to (user, workspace), never copied on fork. Not a content table.
class Progress < ApplicationRecord
  belongs_to :user
  belongs_to :workspace
  belongs_to :trackable, polymorphic: true

  validates :user_id, uniqueness: { scope: %i[workspace_id trackable_type trackable_id] }

  scope :completed, -> { where.not(completed_at: nil) }
  scope :in_progress, -> { where(completed_at: nil).where("resume_seconds > 0") }

  def completed? = completed_at.present?
end
