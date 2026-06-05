class CreateShares < ActiveRecord::Migration[8.1]
  def change
    create_table :shares do |t|
      t.references :workspace, null: false, foreign_key: true
      # Polymorphic across mixed-pk content (Video/Course/Curriculum bigint; Note/Folder uuid),
      # so the id is stored as a string.
      t.string :shareable_type, null: false
      t.string :shareable_id, null: false
      t.integer :visibility, null: false, default: 0
      t.string :token, null: false
      t.references :shared_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
    add_index :shares, :token, unique: true
    add_index :shares, [ :shareable_type, :shareable_id, :workspace_id ], unique: true, name: "index_shares_on_shareable_and_workspace"
  end
end
