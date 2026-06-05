class CreatePositions < ActiveRecord::Migration[8.1]
  def change
    # Curated BJJ taxonomy (Axis 2, docs/decisions/0004) — kept SEPARATE from free-form Tags.
    create_table :positions do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :category, null: false, default: 1
      t.integer :dominance, null: false, default: 1
      t.references :parent, foreign_key: { to_table: :positions }, null: true

      t.timestamps
    end
    add_index :positions, %i[workspace_id name], unique: true

    # Techniques are TYPED EDGES between positions (from → to).
    create_table :techniques do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :name, null: false
      t.references :from_position, foreign_key: { to_table: :positions }, null: true
      t.references :to_position, foreign_key: { to_table: :positions }, null: true
      t.integer :kind, null: false, default: 0

      t.timestamps
    end

    create_table :note_positions do |t|
      t.references :note, type: :uuid, null: false, foreign_key: true
      t.references :position, null: false, foreign_key: true
    end
    add_index :note_positions, %i[note_id position_id], unique: true

    create_table :note_techniques do |t|
      t.references :note, type: :uuid, null: false, foreign_key: true
      t.references :technique, null: false, foreign_key: true
    end
    add_index :note_techniques, %i[note_id technique_id], unique: true
  end
end
