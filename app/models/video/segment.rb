# A labeled time-range within a single video (the in-video "chapter"/clip concept). Notes map
# into segments by their start time (ADR 0011). Workspace-scoped content; seconds are numeric.
#
# Table is `video_segments` — the namespaced-model naming convention (set explicitly so a
# future Video.table_name_prefix can't silently rewrite it). See docs/guides/models-guide.md.
class Video::Segment < ApplicationRecord
  self.table_name = "video_segments"

  acts_as_tenant :workspace
  include Timecoded

  belongs_to :video
  has_many :notes, dependent: :nullify

  validates :start_seconds, presence: true

  scope :for_video, ->(video) { where(video: video).order(:start_seconds, :position) }

  # Adoption (ADR 0011): a closed segment adopts the orphan notes it now owns. Open-ended
  # segments own nothing. No eviction — pinned notes are never touched.
  after_create :adopt_orphan_notes
  after_update :adopt_orphan_notes, if: -> { saved_change_to_end_seconds? || saved_change_to_start_seconds? }

  private

  def adopt_orphan_notes = Notes::SegmentMapper.adopt_orphans_for(self)
end
