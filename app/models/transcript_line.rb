# One timestamped line of a video transcript (Phase 11). Searchable; each result deep-links
# to its moment.
class TranscriptLine < ApplicationRecord
  acts_as_tenant :workspace
  belongs_to :video

  validates :start_seconds, :text, presence: true

  scope :for_video, ->(video) { where(video: video).order(:start_seconds) }

  include PgSearch::Model
  pg_search_scope :search, against: :text, using: { tsearch: { prefix: true } }
end
