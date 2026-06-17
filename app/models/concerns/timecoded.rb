# Shared behaviour for content anchored to a video time-range (Note, Video::Segment).
# Seconds are numeric video offsets (ADR 0004), never wall-clock. A row is a "point" when it
# has only a start, a "range" when it has both bounds.
module Timecoded
  extend ActiveSupport::Concern

  included do
    validate :end_after_start
  end

  def range? = start_seconds.present? && end_seconds.present?
  def point? = start_seconds.present? && end_seconds.blank?

  # A closed [start, end) range that contains the given second. Open-ended rows (no end)
  # never contain anything (ADR 0011).
  def covers?(seconds)
    return false if seconds.nil? || start_seconds.nil? || end_seconds.nil?

    start_seconds <= seconds && seconds < end_seconds
  end

  private

  def end_after_start
    return if end_seconds.blank? || start_seconds.blank?

    errors.add(:end_seconds, "must be after start") if end_seconds < start_seconds
  end
end
