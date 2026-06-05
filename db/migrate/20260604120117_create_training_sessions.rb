class CreateTrainingSessions < ActiveRecord::Migration[8.1]
  def change
    # The training journal (Axis 3, docs/decisions/0004): per-user, bridges watching and
    # doing. BJJ-flavored fields (gi, kind) are kept simple/separable for general use.
    create_table :training_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workspace, null: false, foreign_key: true
      t.date :date, null: false
      t.boolean :gi, null: false, default: true
      t.integer :kind, null: false, default: 0
      t.integer :duration_minutes
      t.string :location
      t.string :partners
      t.text :reflection
      t.integer :intensity

      t.timestamps
    end

    create_table :training_session_notes do |t|
      t.references :training_session, null: false, foreign_key: true
      t.references :note, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end
    add_index :training_session_notes, %i[training_session_id note_id], unique: true
  end
end
