# Shared prop builders for content rendered into Inertia pages (notes, segments).
module ContentJson
  extend ActiveSupport::Concern

  private

  def note_json(note)
    {
      id: note.id,
      noteType: note.note_type,
      videoId: note.video_id,
      segmentId: note.segment_id,
      title: note.title,
      startSeconds: note.start_seconds,
      endSeconds: note.end_seconds,
      body: note.body.to_s,
      categories: note.categories.map { |c| { id: c.id, name: c.name } },
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

  # An athlete with the bits the UI needs to render an avatar: the attached image URL when
  # present, otherwise a coloured initials badge (iteration 0007 scope addition).
  def athlete_json(athlete)
    {
      id: athlete.id,
      name: athlete.name,
      avatarUrl: (rails_blob_path(athlete.avatar) if athlete.avatar.attached?),
      initials: athlete.initials,
      hue: athlete.avatar_hue
    }
  end

  # Video descriptions store rich-text HTML in a plain column; sanitize on the way out so the
  # client can render it directly. (Action Text proper is deferred with the UUID pass — videos
  # are still bigint-keyed; see docs/roadmap/iterations/0007.)
  def sanitized_html(html)
    ActionController::Base.helpers.sanitize(html.to_s).presence
  end
end
