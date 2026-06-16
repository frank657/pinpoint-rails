# Shared prop builders for content rendered into Inertia pages (notes, segments).
module ContentJson
  extend ActiveSupport::Concern

  private

  def note_json(note)
    {
      id: note.id,
      noteType: note.note_type,
      videoId: note.video_id,
      title: note.title,
      startSeconds: note.start_seconds,
      endSeconds: note.end_seconds,
      body: note.body.to_s,
      categoryId: note.category_id,
      category: note.category&.name,
      tags: note.tags.map(&:name),
      positions: note.positions.map { |p| { id: p.id, name: p.name } },
      techniques: note.techniques.map { |t| { id: t.id, name: t.name } },
      createdAt: note.created_at.iso8601
    }
  end

  # Compact card used on the Library, athlete pages, and search results.
  def video_card_json(video)
    {
      id: video.id,
      title: video.title,
      source: video.source,
      status: video.upload_status,
      durationSeconds: video.duration_seconds,
      poster: video_poster(video),
      createdAt: video.created_at.iso8601
    }
  end

  # Poster for a video card / show header. YouTube: the standard thumbnail (free from the id).
  # Uploads: the Vod cover snapshot once it has been pulled into Active Storage
  # (Vod#attach_cover_image_from_provider). The raw Aliyun cover_url is a short-lived signed URL,
  # so we serve the stable AS blob URL; the UI shows a placeholder until it's attached.
  def video_poster(video)
    if video.youtube? && video.youtube_id.present?
      "https://i.ytimg.com/vi/#{video.youtube_id}/hqdefault.jpg"
    elsif video.vod&.cover_image&.attached?
      rails_blob_path(video.vod.cover_image)
    end
  end

  def segment_json(segment)
    {
      id: segment.id,
      title: segment.title,
      startSeconds: segment.start_seconds,
      endSeconds: segment.end_seconds,
      position: segment.position
    }
  end
end
