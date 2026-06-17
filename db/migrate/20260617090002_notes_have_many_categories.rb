class NotesHaveManyCategories < ActiveRecord::Migration[8.1]
  # ADR 0011 / iteration 0007 Phase E: a note can have multiple categories (like tags/positions).
  # Convert the single belongs_to (notes.category_id) into a note_categories join, backfilling
  # the existing single category. Reversible: down restores category_id with the first category.
  def up
    create_table :note_categories do |t|
      t.references :note, type: :uuid, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
    end
    add_index :note_categories, [ :note_id, :category_id ], unique: true

    execute(<<~SQL.squish)
      INSERT INTO note_categories (note_id, category_id)
      SELECT id, category_id FROM notes WHERE category_id IS NOT NULL
    SQL

    remove_reference :notes, :category
  end

  def down
    add_reference :notes, :category, foreign_key: true, index: true
    execute(<<~SQL.squish)
      UPDATE notes SET category_id = sub.category_id
      FROM (SELECT DISTINCT ON (note_id) note_id, category_id
            FROM note_categories ORDER BY note_id, id) sub
      WHERE notes.id = sub.note_id
    SQL
    drop_table :note_categories
  end
end
