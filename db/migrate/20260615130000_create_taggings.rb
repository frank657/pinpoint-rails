# Replaces the note-only `note_tags` HABTM with a polymorphic `taggings` table so a single Tag
# can be applied to Notes (UUID id) and Videos (bigint id) alike. taggable_id is a STRING to
# bridge the two id formats — iteration 0006a, option (i). Reversible: backfills both ways.
class CreateTaggings < ActiveRecord::Migration[8.1]
  def up
    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.string :taggable_type, null: false
      t.string :taggable_id, null: false
      t.references :workspace, null: false, foreign_key: true
      t.timestamps
    end
    add_index :taggings, [ :taggable_type, :taggable_id ]
    add_index :taggings, [ :tag_id, :taggable_type, :taggable_id ],
              unique: true, name: "index_taggings_on_tag_and_taggable"

    # Backfill existing note tags. workspace_id comes from the tag (tags are workspace-scoped).
    execute(<<~SQL.squish)
      INSERT INTO taggings (tag_id, taggable_type, taggable_id, workspace_id, created_at, updated_at)
      SELECT nt.tag_id, 'Note', nt.note_id::text, t.workspace_id, nt.created_at, nt.updated_at
      FROM note_tags nt
      JOIN tags t ON t.id = nt.tag_id
    SQL

    drop_table :note_tags
  end

  def down
    create_table :note_tags do |t|
      t.references :note, null: false, foreign_key: true, type: :uuid
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    add_index :note_tags, [ :note_id, :tag_id ], unique: true

    execute(<<~SQL.squish)
      INSERT INTO note_tags (note_id, tag_id, created_at, updated_at)
      SELECT taggable_id::uuid, tag_id, created_at, updated_at
      FROM taggings
      WHERE taggable_type = 'Note'
    SQL

    drop_table :taggings
  end
end
