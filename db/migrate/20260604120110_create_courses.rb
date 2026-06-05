class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug
      t.text :description

      t.timestamps
    end
    add_index :courses, [ :workspace_id, :slug ], unique: true

    create_table :course_chapters, id: :uuid do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    create_table :course_items do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :video, null: false, foreign_key: true
      t.references :course_chapter, type: :uuid, null: true, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :course_items, [ :course_id, :video_id ], unique: true
  end
end
