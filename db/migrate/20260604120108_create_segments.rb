class CreateSegments < ActiveRecord::Migration[8.1]
  def change
    create_table :segments, id: :uuid do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :video, type: :bigint, null: false, foreign_key: true
      t.string :title
      t.float :start_seconds, null: false
      t.float :end_seconds
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
