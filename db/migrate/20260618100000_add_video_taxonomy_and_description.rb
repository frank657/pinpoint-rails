# Video-level taxonomy (iteration 0007 scope addition): videos carry their own categories,
# positions and techniques — mirroring the note_* HABTM joins (athletes/tags already exist).
# Plus a rich-text (HTML) `description` column on videos. Both are content (ADR 0004 axis 1).
#
# Note: dedicated join tables (not a single polymorphic taxonomy join) keep parity with the
# existing note_categories/note_positions/note_techniques and avoid the mixed-PK (bigint video /
# uuid note) string-id workaround. The polymorphic consolidation is deferred to the UUID pass
# (iteration 0008 / a future ADR), as recorded in docs/roadmap/iterations/0007.
class AddVideoTaxonomyAndDescription < ActiveRecord::Migration[8.1]
  def change
    add_column :videos, :description, :text

    create_table :video_categories do |t|
      t.references :video, null: false, foreign_key: true, type: :bigint
      t.references :category, null: false, foreign_key: true, type: :bigint
    end
    add_index :video_categories, %i[video_id category_id], unique: true

    create_table :video_positions do |t|
      t.references :video, null: false, foreign_key: true, type: :bigint
      t.references :position, null: false, foreign_key: true, type: :bigint
    end
    add_index :video_positions, %i[video_id position_id], unique: true

    create_table :video_techniques do |t|
      t.references :video, null: false, foreign_key: true, type: :bigint
      t.references :technique, null: false, foreign_key: true, type: :bigint
    end
    add_index :video_techniques, %i[video_id technique_id], unique: true
  end
end
