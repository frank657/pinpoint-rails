# Course → Notebook, and drop the Curriculum + Folder concepts (ADR 0010, iteration 0003).
# Order matters: drop FK-dependent tables/columns before the tables they reference, then
# rename, then repoint the polymorphic string columns that stored "Course".
class RenameCourseToNotebook < ActiveRecord::Migration[8.1]
  def up
    # 1. drop the removed concepts (FK dependents first)
    remove_column :notes, :folder_id
    drop_table :curriculum_items
    drop_table :curriculums
    drop_table :folders

    # 2. rename tables (Rails also renames the conventionally-named indexes + pk sequence)
    rename_table :courses, :notebooks
    rename_table :course_chapters, :notebook_chapters
    rename_table :course_items, :notebook_items

    # 3. rename FK columns
    rename_column :notebook_chapters, :course_id, :notebook_id
    rename_column :notebook_items, :course_id, :notebook_id
    rename_column :notebook_items, :course_chapter_id, :notebook_chapter_id

    # 4. repoint polymorphic references that stored "Course"; drop dropped-type rows
    execute <<~SQL.squish
      UPDATE shares SET shareable_type = 'Notebook' WHERE shareable_type = 'Course';
    SQL
    execute <<~SQL.squish
      DELETE FROM shares WHERE shareable_type IN ('Curriculum', 'Folder');
    SQL
    execute <<~SQL.squish
      UPDATE forks SET source_type = 'Notebook' WHERE source_type = 'Course';
    SQL
    execute <<~SQL.squish
      UPDATE forks SET target_type = 'Notebook' WHERE target_type = 'Course';
    SQL
    execute <<~SQL.squish
      DELETE FROM forks WHERE source_type IN ('Curriculum', 'Folder') OR target_type IN ('Curriculum', 'Folder');
    SQL
    execute <<~SQL.squish
      UPDATE progresses SET trackable_type = 'Notebook' WHERE trackable_type = 'Course';
    SQL
    execute <<~SQL.squish
      DELETE FROM progresses WHERE trackable_type IN ('Curriculum', 'Folder');
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Notebook rename (ADR 0010) is one-way; restore from backup if needed."
  end
end
