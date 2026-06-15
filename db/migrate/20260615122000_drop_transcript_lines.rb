class DropTranscriptLines < ActiveRecord::Migration[8.1]
  # Removes the transcript feature (TranscriptLine, Axis 1 content) along with ASR/import
  # and the AI summary layer that read from it. Reversible: #down recreates the table exactly
  # as 20260604120119_create_transcript_lines did.
  def up
    drop_table :transcript_lines
  end

  def down
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
