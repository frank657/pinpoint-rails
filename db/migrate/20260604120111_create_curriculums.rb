class CreateCurriculums < ActiveRecord::Migration[8.1]
  def change
    create_table :curriculums do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug
      t.text :description

      t.timestamps
    end
    add_index :curriculums, [ :workspace_id, :slug ], unique: true

    create_table :curriculum_items do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :curriculum, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :curriculum_items, [ :curriculum_id, :course_id ], unique: true
  end
end
