class CreateFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :folders do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :folders }, null: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_foreign_key :notes, :folders, column: :folder_id
  end
end
