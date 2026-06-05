class CreateProgresses < ActiveRecord::Migration[8.1]
  def change
    # Per-user learning state (Axis 3, docs/decisions/0004) — NEVER on content tables.
    create_table :progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workspace, null: false, foreign_key: true
      t.string :trackable_type, null: false
      t.bigint :trackable_id, null: false
      t.datetime :completed_at
      t.float :resume_seconds, default: 0, null: false
      t.datetime :last_viewed_at

      t.timestamps
    end
    add_index :progresses, %i[user_id workspace_id trackable_type trackable_id],
              unique: true, name: "index_progress_unique"
  end
end
