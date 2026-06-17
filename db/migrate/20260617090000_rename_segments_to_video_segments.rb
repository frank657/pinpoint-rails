class RenameSegmentsToVideoSegments < ActiveRecord::Migration[8.1]
  # Video::Segment now follows the namespaced-model table convention (ADR 0011 / models-guide):
  # the table is its full underscored name. rename_table also renames the dependent indexes.
  def change
    rename_table :segments, :video_segments
  end
end
