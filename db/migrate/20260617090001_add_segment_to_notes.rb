class AddSegmentToNotes < ActiveRecord::Migration[8.1]
  # ADR 0011: a note stores its segment. null = orphan (auto-mappable); set = pinned.
  # FK nullifies on segment delete so deleting a segment orphans its notes (scenario #12).
  def change
    add_reference :notes, :segment, type: :uuid, null: true,
                  foreign_key: { to_table: :video_segments, on_delete: :nullify }, index: true
    # Match the notes index for time-ordered fetch + containment scans.
    add_index :video_segments, [ :video_id, :start_seconds ]
  end
end
