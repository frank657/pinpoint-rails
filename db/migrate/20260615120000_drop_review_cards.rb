class DropReviewCards < ActiveRecord::Migration[8.1]
  # Removes the spaced-repetition review feature (ReviewCard, Axis 3 per-user state).
  # Reversible: #down recreates the table exactly as 20260604120116_create_review_cards did,
  # so the feature can be reintroduced later by rolling forward again.
  def up
    drop_table :review_cards
  end

  def down
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
