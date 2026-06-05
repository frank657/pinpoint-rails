class CreateVideos < ActiveRecord::Migration[8.1]
  def change
    create_table :videos do |t|
      t.references :workspace, null: false, foreign_key: true
      t.integer :source, null: false, default: 0
      t.string :title, null: false
      t.float :duration_seconds
      t.string :youtube_id
      t.text :transcript
      t.references :vod, type: :uuid, foreign_key: true, null: true
      t.references :uploaded_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :videos, [ :workspace_id, :youtube_id ]
  end
end
