class CreateReviewCards < ActiveRecord::Migration[8.1]
  def change
    # A spaced-repetition card derived from a Note. Note ≠ Card (Anki model, docs/decisions/
    # 0004): scheduling state is per-user (Axis 3) and never lives on the Note.
    create_table :review_cards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :note, type: :uuid, null: false, foreign_key: true
      t.string :card_template, null: false, default: "basic"
      t.integer :state, null: false, default: 0
      t.datetime :due_at
      t.float :stability, null: false, default: 0
      t.float :difficulty, null: false, default: 0
      t.integer :reps, null: false, default: 0
      t.integer :lapses, null: false, default: 0
      t.integer :interval_days, null: false, default: 0
      t.datetime :last_reviewed_at

      t.timestamps
    end
    add_index :review_cards, %i[user_id note_id card_template], unique: true
    add_index :review_cards, :due_at
  end
end
