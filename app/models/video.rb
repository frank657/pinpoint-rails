# A watchable item — either an uploaded file (backed by a Vod / Aliyun VOD) or a YouTube
# link. Notes and segments hang off it. Workspace-scoped content that is forkable
# (docs/decisions/0005).
class Video < ApplicationRecord
  acts_as_tenant :workspace
  include Shareable
  include Taggable

  enum :source, { upload: 0, youtube: 1 }

  belongs_to :vod, optional: true
  belongs_to :uploaded_by, class_name: "User", optional: true
  has_many :notes, dependent: :destroy
  has_many :segments, class_name: "Video::Segment", dependent: :destroy
  has_and_belongs_to_many :athletes, join_table: :video_athletes

  validates :title, presence: true
  validates :youtube_id, presence: true, if: :youtube?
  validates :vod, presence: true, if: :upload?

  after_destroy :cleanup_orphaned_vod

  # --- Library filters & search (iteration 0006b) ---
  scope :search,      ->(q) { where("title ILIKE ?", "%#{sanitize_sql_like(q.to_s)}%") }
  scope :from_source, ->(s) { where(source: s) }
  # Wrapped in a subquery (not a bare `joins`) so the outer relation stays join-free — otherwise
  # a later `includes(:tags)` gets promoted to an eager-load JOIN that breaks on the polymorphic
  # string taggable_id (varchar = bigint).
  scope :featuring, ->(name) { where(id: joins(:athletes).where(athletes: { name: name }).select(:id)) }
  # Videos carry tags polymorphically with a STRING taggable_id, so videos.id (bigint) can't be
  # SQL-joined against it directly — match via a casted subquery instead (iteration 0006a).
  scope :with_tag, ->(name) {
    where(id: Tagging.joins(:tag).where(taggable_type: "Video", tags: { name: name })
                     .select(Arel.sql("taggable_id::bigint")))
  }
  scope :added_between, ->(from, to) {
    rel = all
    rel = rel.where("videos.created_at >= ?", from) if from.present?
    rel = rel.where("videos.created_at <= ?", to) if to.present?
    rel
  }

  # Whether the video can be played yet.
  def playable?
    youtube? || (vod.present? && (vod.ready? || vod.uploaded?))
  end

  # Upload status surfaced to the client (YouTube is always ready).
  def upload_status
    return "ready" if youtube?

    vod&.status || "uploading"
  end

  # Replace this video's featured athletes from a list of names (find-or-create, de-duped).
  def athlete_names=(names)
    self.athletes = Athlete.for_names(names)
  end

  def athlete_names
    athletes.map(&:name)
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
