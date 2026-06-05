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
      createdAt: note.created_at.iso8601
    }
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
