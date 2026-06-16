# The provider-backed media asset (Aliyun VOD). Ported from method-channel (ADR 0007).
#
# A Vod is SHARED media (NOT acts_as_tenant): it is reference-counted by the Videos that
# point at it, so a forked Video can reuse the same underlying asset without re-uploading
# (docs/decisions/0005). The Aliyun object is destroyed only when the last Video is gone —
# enforced in Video#cleanup_orphaned_vod, not here.
class Vod < ApplicationRecord
  include Providers

  enum :status, { uploading: 0, uploaded: 1, ready: 2 }
  enum :provider, { aliyun: 0 }

  belongs_to :uploaded_by, class_name: "User", optional: true
  # Lifecycle is managed by reference counting (Video#cleanup_orphaned_vod): a Vod is only
  # destroyed once no Video references it, so no `dependent:` is needed here — and adding one
  # would query the tenant-scoped Video from non-request contexts (webhooks, jobs) where no
  # tenant is set, raising NoTenantSet. See docs/decisions/0005.
  has_many :videos
  has_one_attached :cover_image

  validates :key, uniqueness: true, allow_blank: true

  scope :upload_expired, -> { where("upload_expires_at IS NOT NULL AND upload_expires_at <= ?", Time.current) }
  scope :upload_alive,   -> { where("upload_expires_at IS NULL OR upload_expires_at > ?", Time.current) }

  DORMANT_AFTER = 1.day
  scope :dormant, ->(older_than: DORMANT_AFTER) {
    where(status: :uploading).where("created_at < ?", Time.current - older_than)
  }

  before_save :set_status_timestamps
  after_create :create_aliyun_upload_data, if: :aliyun?
  after_destroy :destroy_vod_object

  def upload_expired?
    upload_expires_at.present? && upload_expires_at <= Time.current
  end

  # After transcode, pull the generated cover from the provider into Active Storage. The
  # provider cover_url is a short-lived signed URL, so we download a stable copy. Idempotent:
  # safe to call again from a repeat callback or the backfill task.
  def attach_cover_image_from_provider
    return unless aliyun?
    return if cover_image.attached?

    url = aliyun_video&.cover_url
    FileService.attach_url(cover_image, url) if url.present?
  end

  def urls
    aliyun_video.urls if aliyun?
  end

  def url(format = "m3u8")
    aliyun_video.url(format) if aliyun?
  end

  private

  def set_status_timestamps
    return unless will_save_change_to_status?

    case status
    when "uploaded" then self.uploaded_at ||= Time.current
    when "ready"    then self.ready_at ||= Time.current
    end
  end
end
