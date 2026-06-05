class CreateTranscriptLines < ActiveRecord::Migration[8.1]
  def change
    # Timestamped transcript lines (Axis 1 content). Numeric seconds so search results seek
    # the player (docs/decisions/0004).
    create_table :transcript_lines do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :video, null: false, foreign_key: true
      t.float :start_seconds, null: false
      t.float :end_seconds
      t.text :text, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :transcript_lines, %i[video_id start_seconds]
  end
end
