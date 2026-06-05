class CreateVods < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :vods, id: :uuid do |t|
      t.string   :key
      t.integer  :status, null: false, default: 0
      t.integer  :provider, null: false, default: 0
      t.string   :filename
      t.string   :title
      t.float    :duration
      t.datetime :upload_expires_at
      t.datetime :uploaded_at
      t.datetime :ready_at
      t.references :uploaded_by, foreign_key: { to_table: :users }, null: true
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :vods, :key, unique: true
    add_index :vods, :upload_expires_at
  end
end
