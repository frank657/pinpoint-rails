# A note — either a TIMESTAMP note anchored to a moment/range in a video, or a free-standing
# RICH_TEXT note (Action Text body, images via Active Storage). Workspace-scoped content
# (docs/decisions/0004). Timestamps are numeric SECONDS, never formatted strings.
#
# A timed note maps into the segment that contains its start (ADR 0011): `segment_id` null =
# orphan (auto-mappable); set = pinned (locked, never auto-remapped).
class Note < ApplicationRecord
  acts_as_tenant :workspace
  include Shareable
  include Taggable
  include Timecoded
  has_paper_trail

  enum :note_type, { timestamp: 0, rich_text: 1 }

  belongs_to :video, optional: true
  belongs_to :segment, class_name: "Video::Segment", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_and_belongs_to_many :categories, join_table: :note_categories
  has_and_belongs_to_many :positions, join_table: :note_positions
  has_and_belongs_to_many :techniques, join_table: :note_techniques
  has_rich_text :body

  validates :video, presence: true, if: :timestamp?
  validates :start_seconds, presence: true, if: :timestamp?

  scope :for_video, ->(video) { where(video: video).order(:start_seconds, :created_at) }

  include PgSearch::Model
  pg_search_scope :search, against: :title,
    associated_against: { rich_text_body: :body },
    using: { tsearch: { prefix: true } }

  # Auto-map into a segment on create / when the start time changes — orphans only; a pinned
  # note (already has a segment) is never moved automatically (ADR 0011).
  after_create :map_to_segment
  after_update :map_to_segment, if: :saved_change_to_start_seconds?

  private

  def map_to_segment = Notes::SegmentMapper.map_orphan(self)
end
