class CreateAthletes < ActiveRecord::Migration[8.1]
  def change
    # A person featured in a video — coach or athlete (Axis-2 taxonomy, ADR 0004).
    create_table :athletes do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
    add_index :athletes, [ :workspace_id, :name ], unique: true
  end
end
