class DropNotebooks < ActiveRecord::Migration[8.1]
  # Removes the Notebook content feature (Notebook + Chapter + Item). Drops FK-dependent
  # tables first. #down recreates the tables as they stood after 20260605120000, so the
  # feature can be reintroduced later by rolling forward again.
  def up
    drop_table :notebook_items
    drop_table :notebook_chapters
    drop_table :notebooks
  end

  def down
    create_table :notebooks do |t|
      t.text :description
      t.string :slug
      t.string :title, null: false
      t.references :workspace, null: false, foreign_key: true
      t.timestamps
    end
    add_index :notebooks, %i[workspace_id slug], unique: true

    create_table :notebook_chapters, id: :uuid do |t|
      t.references :notebook, null: false, foreign_key: true
      t.integer :position, default: 0, null: false
      t.string :title, null: false
      t.references :workspace, null: false, foreign_key: true
      t.timestamps
    end

    create_table :notebook_items do |t|
      t.uuid :notebook_chapter_id
      t.references :notebook, null: false, foreign_key: true
      t.integer :position, default: 0, null: false
      t.references :video, null: false, foreign_key: true
      t.references :workspace, null: false, foreign_key: true
      t.timestamps
    end
    add_index :notebook_items, %i[notebook_id video_id], unique: true
    add_index :notebook_items, :notebook_chapter_id
    add_foreign_key :notebook_items, :notebook_chapters
  end
end
