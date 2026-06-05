# A note — either a TIMESTAMP note anchored to a moment/range in a video, or a free-standing
# RICH_TEXT note (Action Text body, images via Active Storage). Workspace-scoped content
# (docs/decisions/0004). Timestamps are numeric SECONDS, never formatted strings.
class Note < ApplicationRecord
  acts_as_tenant :workspace
  include Shareable
  has_paper_trail

  enum :note_type, { timestamp: 0, rich_text: 1 }

  belongs_to :video, optional: true
  belongs_to :category, optional: true
  belongs_to :folder, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_and_belongs_to_many :tags, join_table: :note_tags
  has_and_belongs_to_many :positions, join_table: :note_positions
  has_and_belongs_to_many :techniques, join_table: :note_techniques
  has_rich_text :body

  validates :video, presence: true, if: :timestamp?
  validates :start_seconds, presence: true, if: :timestamp?
  validate :end_after_start

  scope :for_video, ->(video) { where(video: video).order(:start_seconds, :created_at) }

  include PgSearch::Model
  pg_search_scope :search, against: :title,
    associated_against: { rich_text_body: :body },
    using: { tsearch: { prefix: true } }

  # A range note has both bounds; a point note has only start_seconds.
  def range? = start_seconds.present? && end_seconds.present?

  private

  def end_after_start
    return if end_seconds.blank? || start_seconds.blank?

    errors.add(:end_seconds, "must be after start") if end_seconds < start_seconds
  end
end
