class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes, id: :uuid do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :video, type: :bigint, foreign_key: true, null: true
      t.references :category, foreign_key: true, null: true
      t.bigint :folder_id # reserved for Phase 4 (Folders); no FK yet
      t.integer :note_type, null: false, default: 0
      t.string :title
      t.float :start_seconds
      t.float :end_seconds
      t.references :created_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
    add_index :notes, :folder_id
    add_index :notes, [ :video_id, :start_seconds ]
  end
end
