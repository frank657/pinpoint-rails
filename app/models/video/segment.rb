# A labeled time-range within a single video (the in-video "chapter"/clip concept).
# Workspace-scoped content. Seconds are numeric.
#
# Table stays "segments": Rails derives it from the demodulized name, set explicitly per the
# CLAUDE.md convention so a future Video.table_name_prefix can't silently rewrite it.
class Video::Segment < ApplicationRecord
  self.table_name = "segments"

  acts_as_tenant :workspace

  belongs_to :video

  validates :start_seconds, presence: true
  validate :end_after_start

  scope :for_video, ->(video) { where(video: video).order(:position, :start_seconds) }

  private

  def end_after_start
    return if end_seconds.blank? || start_seconds.blank?

    errors.add(:end_seconds, "must be after start") if end_seconds < start_seconds
  end
end
