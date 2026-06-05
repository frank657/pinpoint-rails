class CreateForks < ActiveRecord::Migration[8.1]
  def change
    # Attribution only — links a forked copy back to its source (docs/decisions/0005).
    # Global (spans workspaces), so NOT acts_as_tenant.
    create_table :forks do |t|
      t.string :source_type, null: false
      t.string :source_id, null: false
      t.references :source_workspace, foreign_key: { to_table: :workspaces }, null: true
      t.string :target_type, null: false
      t.string :target_id, null: false
      t.references :target_workspace, foreign_key: { to_table: :workspaces }, null: false
      t.references :forked_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
    add_index :forks, [ :target_type, :target_id ]
    add_index :forks, [ :source_type, :source_id ]
  end
end
