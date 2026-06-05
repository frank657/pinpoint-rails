# A watchable item — either an uploaded file (backed by a Vod / Aliyun VOD) or a YouTube
# link. Notes and segments hang off it in later phases. Workspace-scoped content that is
# reusable across courses and forkable (docs/decisions/0003, 0005).
class Video < ApplicationRecord
  acts_as_tenant :workspace
  include Shareable

  enum :source, { upload: 0, youtube: 1 }

  belongs_to :vod, optional: true
  belongs_to :uploaded_by, class_name: "User", optional: true
  has_many :notes, dependent: :destroy
  has_many :segments, dependent: :destroy
  has_many :transcript_lines, dependent: :destroy
  # Removing a video from a course deletes the join, not the video; deleting a video cleans
  # its joins (docs/decisions/0003).
  has_many :course_items, class_name: "Course::Item", dependent: :destroy

  validates :title, presence: true
  validates :youtube_id, presence: true, if: :youtube?
  validates :vod, presence: true, if: :upload?

  after_destroy :cleanup_orphaned_vod

  # Whether the video can be played yet.
  def playable?
    youtube? || (vod.present? && (vod.ready? || vod.uploaded?))
  end

  # Upload status surfaced to the client (YouTube is always ready).
  def upload_status
    return "ready" if youtube?

    vod&.status || "uploading"
  end

  private

  # Reference-counted Vod cleanup (docs/decisions/0005): destroy the shared Aliyun asset
  # only when no Video in ANY workspace still points at it.
  def cleanup_orphaned_vod
    return unless vod_id

    still_referenced = ActsAsTenant.without_tenant do
      Video.where(vod_id: vod_id).where.not(id: id).exists?
    end
    vod&.destroy unless still_referenced
  end
end
