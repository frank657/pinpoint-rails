# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_18_110000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "athletes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.uuid "workspace_id", null: false
    t.index ["workspace_id", "name"], name: "index_athletes_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_athletes_on_workspace_id"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.uuid "workspace_id", null: false
    t.index ["workspace_id", "name"], name: "index_categories_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_categories_on_workspace_id"
  end

  create_table "forks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "forked_by_id"
    t.uuid "source_id", null: false
    t.string "source_type", null: false
    t.uuid "source_workspace_id"
    t.uuid "target_id", null: false
    t.string "target_type", null: false
    t.uuid "target_workspace_id", null: false
    t.datetime "updated_at", null: false
    t.index ["forked_by_id"], name: "index_forks_on_forked_by_id"
    t.index ["source_type", "source_id"], name: "index_forks_on_source_type_and_source_id"
    t.index ["source_workspace_id"], name: "index_forks_on_source_workspace_id"
    t.index ["target_type", "target_id"], name: "index_forks_on_target_type_and_target_id"
    t.index ["target_workspace_id"], name: "index_forks_on_target_workspace_id"
  end

  create_table "note_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.uuid "note_id", null: false
    t.index ["category_id"], name: "index_note_categories_on_category_id"
    t.index ["note_id", "category_id"], name: "index_note_categories_on_note_id_and_category_id", unique: true
    t.index ["note_id"], name: "index_note_categories_on_note_id"
  end

  create_table "note_positions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "note_id", null: false
    t.uuid "position_id", null: false
    t.index ["note_id", "position_id"], name: "index_note_positions_on_note_id_and_position_id", unique: true
    t.index ["note_id"], name: "index_note_positions_on_note_id"
    t.index ["position_id"], name: "index_note_positions_on_position_id"
  end

  create_table "note_techniques", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "note_id", null: false
    t.uuid "technique_id", null: false
    t.index ["note_id", "technique_id"], name: "index_note_techniques_on_note_id_and_technique_id", unique: true
    t.index ["note_id"], name: "index_note_techniques_on_note_id"
    t.index ["technique_id"], name: "index_note_techniques_on_technique_id"
  end

  create_table "notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.float "end_seconds"
    t.integer "note_type", default: 0, null: false
    t.uuid "segment_id"
    t.float "start_seconds"
    t.string "title"
    t.datetime "updated_at", null: false
    t.uuid "video_id"
    t.uuid "workspace_id", null: false
    t.index ["created_by_id"], name: "index_notes_on_created_by_id"
    t.index ["segment_id"], name: "index_notes_on_segment_id"
    t.index ["video_id", "start_seconds"], name: "index_notes_on_video_id_and_start_seconds"
    t.index ["video_id"], name: "index_notes_on_video_id"
    t.index ["workspace_id"], name: "index_notes_on_workspace_id"
  end

  create_table "positions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "category", default: 1, null: false
    t.datetime "created_at", null: false
    t.integer "dominance", default: 1, null: false
    t.string "name", null: false
    t.uuid "parent_id"
    t.datetime "updated_at", null: false
    t.uuid "workspace_id", null: false
    t.index ["parent_id"], name: "index_positions_on_parent_id"
    t.index ["workspace_id", "name"], name: "index_positions_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_positions_on_workspace_id"
  end

  create_table "progresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "last_viewed_at"
    t.float "resume_seconds", default: 0.0, null: false
    t.uuid "trackable_id", null: false
    t.string "trackable_type", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.uuid "workspace_id", null: false
    t.index ["user_id", "workspace_id", "trackable_type", "trackable_id"], name: "index_progress_unique", unique: true
    t.index ["user_id"], name: "index_progresses_on_user_id"
    t.index ["workspace_id"], name: "index_progresses_on_workspace_id"
  end

  create_table "shares", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "shareable_id", null: false
    t.string "shareable_type", null: false
    t.uuid "shared_by_id"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.uuid "workspace_id", null: false
    t.index ["shareable_type", "shareable_id", "workspace_id"], name: "index_shares_on_shareable_and_workspace", unique: true
    t.index ["shared_by_id"], name: "index_shares_on_shared_by_id"
    t.index ["token"], name: "index_shares_on_token", unique: true
    t.index ["workspace_id"], name: "index_shares_on_workspace_id"
  end

  create_table "taggings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "tag_id", null: false
    t.uuid "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "updated_at", null: false
    t.uuid "workspace_id", null: false
    t.index ["tag_id", "taggable_type", "taggable_id"], name: "index_taggings_on_tag_and_taggable", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["workspace_id"], name: "index_taggings_on_workspace_id"
  end

  create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.uuid "workspace_id", null: false
    t.index ["workspace_id", "name"], name: "index_tags_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_tags_on_workspace_id"
  end

  create_table "techniques", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "from_position_id"
    t.integer "kind", default: 0, null: false
    t.string "name", null: false
    t.uuid "to_position_id"
    t.datetime "updated_at", null: false
    t.uuid "workspace_id", null: false
    t.index ["from_position_id"], name: "index_techniques_on_from_position_id"
    t.index ["to_position_id"], name: "index_techniques_on_to_position_id"
    t.index ["workspace_id"], name: "index_techniques_on_workspace_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.uuid "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "video_athletes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "athlete_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "video_id", null: false
    t.index ["athlete_id"], name: "index_video_athletes_on_athlete_id"
    t.index ["video_id", "athlete_id"], name: "index_video_athletes_on_video_id_and_athlete_id", unique: true
    t.index ["video_id"], name: "index_video_athletes_on_video_id"
  end

  create_table "video_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.uuid "video_id", null: false
    t.index ["category_id"], name: "index_video_categories_on_category_id"
    t.index ["video_id", "category_id"], name: "index_video_categories_on_video_id_and_category_id", unique: true
    t.index ["video_id"], name: "index_video_categories_on_video_id"
  end

  create_table "video_positions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "position_id", null: false
    t.uuid "video_id", null: false
    t.index ["position_id"], name: "index_video_positions_on_position_id"
    t.index ["video_id", "position_id"], name: "index_video_positions_on_video_id_and_position_id", unique: true
    t.index ["video_id"], name: "index_video_positions_on_video_id"
  end

  create_table "video_segments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "end_seconds"
    t.integer "position", default: 0, null: false
    t.float "start_seconds", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.uuid "video_id", null: false
    t.uuid "workspace_id", null: false
    t.index ["video_id", "start_seconds"], name: "index_video_segments_on_video_id_and_start_seconds"
    t.index ["video_id"], name: "index_video_segments_on_video_id"
    t.index ["workspace_id"], name: "index_video_segments_on_workspace_id"
  end

  create_table "video_techniques", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "technique_id", null: false
    t.uuid "video_id", null: false
    t.index ["technique_id"], name: "index_video_techniques_on_technique_id"
    t.index ["video_id", "technique_id"], name: "index_video_techniques_on_video_id_and_technique_id", unique: true
    t.index ["video_id"], name: "index_video_techniques_on_video_id"
  end

  create_table "videos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.float "duration_seconds"
    t.integer "source", default: 0, null: false
    t.string "title", null: false
    t.text "transcript"
    t.datetime "updated_at", null: false
    t.uuid "uploaded_by_id"
    t.uuid "vod_id"
    t.uuid "workspace_id", null: false
    t.string "youtube_id"
    t.index ["uploaded_by_id"], name: "index_videos_on_uploaded_by_id"
    t.index ["vod_id"], name: "index_videos_on_vod_id"
    t.index ["workspace_id", "youtube_id"], name: "index_videos_on_workspace_id_and_youtube_id"
    t.index ["workspace_id"], name: "index_videos_on_workspace_id"
  end

  create_table "vods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "duration"
    t.string "filename"
    t.string "key"
    t.jsonb "metadata", default: {}
    t.integer "provider", default: 0, null: false
    t.datetime "ready_at"
    t.integer "status", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.datetime "upload_expires_at"
    t.datetime "uploaded_at"
    t.uuid "uploaded_by_id"
    t.index ["key"], name: "index_vods_on_key", unique: true
    t.index ["upload_expires_at"], name: "index_vods_on_upload_expires_at"
    t.index ["uploaded_by_id"], name: "index_vods_on_uploaded_by_id"
  end

  create_table "workspace_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.uuid "workspace_id", null: false
    t.index ["user_id", "workspace_id"], name: "index_workspace_memberships_on_user_id_and_workspace_id", unique: true
    t.index ["user_id"], name: "index_workspace_memberships_on_user_id"
    t.index ["workspace_id"], name: "index_workspace_memberships_on_workspace_id"
  end

  create_table "workspaces", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_workspaces_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "athletes", "workspaces"
  add_foreign_key "categories", "workspaces"
  add_foreign_key "forks", "users", column: "forked_by_id"
  add_foreign_key "forks", "workspaces", column: "source_workspace_id"
  add_foreign_key "forks", "workspaces", column: "target_workspace_id"
  add_foreign_key "note_categories", "categories"
  add_foreign_key "note_categories", "notes"
  add_foreign_key "note_positions", "notes"
  add_foreign_key "note_positions", "positions"
  add_foreign_key "note_techniques", "notes"
  add_foreign_key "note_techniques", "techniques"
  add_foreign_key "notes", "users", column: "created_by_id"
  add_foreign_key "notes", "video_segments", column: "segment_id", on_delete: :nullify
  add_foreign_key "notes", "videos"
  add_foreign_key "notes", "workspaces"
  add_foreign_key "positions", "positions", column: "parent_id"
  add_foreign_key "positions", "workspaces"
  add_foreign_key "progresses", "users"
  add_foreign_key "progresses", "workspaces"
  add_foreign_key "shares", "users", column: "shared_by_id"
  add_foreign_key "shares", "workspaces"
  add_foreign_key "taggings", "tags"
  add_foreign_key "taggings", "workspaces"
  add_foreign_key "tags", "workspaces"
  add_foreign_key "techniques", "positions", column: "from_position_id"
  add_foreign_key "techniques", "positions", column: "to_position_id"
  add_foreign_key "techniques", "workspaces"
  add_foreign_key "video_athletes", "athletes"
  add_foreign_key "video_athletes", "videos"
  add_foreign_key "video_categories", "categories"
  add_foreign_key "video_categories", "videos"
  add_foreign_key "video_positions", "positions"
  add_foreign_key "video_positions", "videos"
  add_foreign_key "video_segments", "videos"
  add_foreign_key "video_segments", "workspaces"
  add_foreign_key "video_techniques", "techniques"
  add_foreign_key "video_techniques", "videos"
  add_foreign_key "videos", "users", column: "uploaded_by_id"
  add_foreign_key "videos", "vods"
  add_foreign_key "videos", "workspaces"
  add_foreign_key "vods", "users", column: "uploaded_by_id"
  add_foreign_key "workspace_memberships", "users"
  add_foreign_key "workspace_memberships", "workspaces"
end
