class CreateVideoAthletes < ActiveRecord::Migration[8.1]
  def change
    create_table :video_athletes do |t|
      t.references :video, null: false, foreign_key: true
      t.references :athlete, null: false, foreign_key: true

      t.timestamps
    end
    add_index :video_athletes, [ :video_id, :athlete_id ], unique: true
  end
end
