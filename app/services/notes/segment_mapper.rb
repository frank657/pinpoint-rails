# Maps notes into segments by start time (ADR 0011). The one rule: a timed note belongs to the
# closed segment whose [start, end) contains its start; on overlap the earliest-created wins.
# Auto-mapping only ever touches ORPHAN notes (segment_id nil) — pinned notes are never moved,
# and there is no eviction. All writes use update_column so they don't re-fire callbacks.
module Notes
  module SegmentMapper
    module_function

    # The closed segment that should own this note, or nil (gap / open-ended / untimed).
    def segment_for(note)
      return nil if note.start_seconds.nil? || note.video_id.nil?

      Video::Segment
        .where(video_id: note.video_id).where.not(end_seconds: nil)
        .where("start_seconds <= :t AND :t < end_seconds", t: note.start_seconds)
        .order(:created_at, :id).first
    end

    # On note create / start-time edit — adopt only if the note is still an orphan.
    def map_orphan(note)
      return unless note.segment_id.nil?

      owner = segment_for(note)
      note.update_column(:segment_id, owner.id) if owner
    end

    # On segment create / end-or-start edit — adopt the orphan notes this segment now owns.
    # Earliest-created wins, so only adopt when this segment is the computed owner.
    def adopt_orphans_for(segment)
      return if segment.end_seconds.nil?

      Note.where(video_id: segment.video_id, segment_id: nil).where.not(start_seconds: nil)
          .where("start_seconds >= :s AND start_seconds < :e", s: segment.start_seconds, e: segment.end_seconds)
          .find_each do |note|
        note.update_column(:segment_id, segment.id) if segment_for(note)&.id == segment.id
      end
    end
  end
end
