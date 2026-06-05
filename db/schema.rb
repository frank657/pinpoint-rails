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

ActiveRecord::Schema[8.1].define(version: 2026_06_04_120119) do
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

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["workspace_id", "name"], name: "index_categories_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_categories_on_workspace_id"
  end

  create_table "course_chapters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["course_id"], name: "index_course_chapters_on_course_id"
    t.index ["workspace_id"], name: "index_course_chapters_on_workspace_id"
  end

  create_table "course_items", force: :cascade do |t|
    t.uuid "course_chapter_id"
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "video_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["course_chapter_id"], name: "index_course_items_on_course_chapter_id"
    t.index ["course_id", "video_id"], name: "index_course_items_on_course_id_and_video_id", unique: true
    t.index ["course_id"], name: "index_course_items_on_course_id"
    t.index ["video_id"], name: "index_course_items_on_video_id"
    t.index ["workspace_id"], name: "index_course_items_on_workspace_id"
  end

  create_table "courses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "slug"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["workspace_id", "slug"], name: "index_courses_on_workspace_id_and_slug", unique: true
    t.index ["workspace_id"], name: "index_courses_on_workspace_id"
  end

  create_table "curriculum_items", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.bigint "curriculum_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["course_id"], name: "index_curriculum_items_on_course_id"
    t.index ["curriculum_id", "course_id"], name: "index_curriculum_items_on_curriculum_id_and_course_id", unique: true
    t.index ["curriculum_id"], name: "index_curriculum_items_on_curriculum_id"
    t.index ["workspace_id"], name: "index_curriculum_items_on_workspace_id"
  end

  create_table "curriculums", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "slug"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["workspace_id", "slug"], name: "index_curriculums_on_workspace_id_and_slug", unique: true
    t.index ["workspace_id"], name: "index_curriculums_on_workspace_id"
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["parent_id"], name: "index_folders_on_parent_id"
    t.index ["workspace_id"], name: "index_folders_on_workspace_id"
  end

  create_table "forks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "forked_by_id"
    t.string "source_id", null: false
    t.string "source_type", null: false
    t.bigint "source_workspace_id"
    t.string "target_id", null: false
    t.string "target_type", null: false
    t.bigint "target_workspace_id", null: false
    t.datetime "updated_at", null: false
    t.index ["forked_by_id"], name: "index_forks_on_forked_by_id"
    t.index ["source_type", "source_id"], name: "index_forks_on_source_type_and_source_id"
    t.index ["source_workspace_id"], name: "index_forks_on_source_workspace_id"
    t.index ["target_type", "target_id"], name: "index_forks_on_target_type_and_target_id"
    t.index ["target_workspace_id"], name: "index_forks_on_target_workspace_id"
  end

  create_table "note_positions", force: :cascade do |t|
    t.uuid "note_id", null: false
    t.bigint "position_id", null: false
    t.index ["note_id", "position_id"], name: "index_note_positions_on_note_id_and_position_id", unique: true
    t.index ["note_id"], name: "index_note_positions_on_note_id"
    t.index ["position_id"], name: "index_note_positions_on_position_id"
  end

  create_table "note_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "note_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id", "tag_id"], name: "index_note_tags_on_note_id_and_tag_id", unique: true
    t.index ["note_id"], name: "index_note_tags_on_note_id"
    t.index ["tag_id"], name: "index_note_tags_on_tag_id"
  end

  create_table "note_techniques", force: :cascade do |t|
    t.uuid "note_id", null: false
    t.bigint "technique_id", null: false
    t.index ["note_id", "technique_id"], name: "index_note_techniques_on_note_id_and_technique_id", unique: true
    t.index ["note_id"], name: "index_note_techniques_on_note_id"
    t.index ["technique_id"], name: "index_note_techniques_on_technique_id"
  end

  create_table "notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.float "end_seconds"
    t.bigint "folder_id"
    t.integer "note_type", default: 0, null: false
    t.float "start_seconds"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "video_id"
    t.bigint "workspace_id", null: false
    t.index ["category_id"], name: "index_notes_on_category_id"
    t.index ["created_by_id"], name: "index_notes_on_created_by_id"
    t.index ["folder_id"], name: "index_notes_on_folder_id"
    t.index ["video_id", "start_seconds"], name: "index_notes_on_video_id_and_start_seconds"
    t.index ["video_id"], name: "index_notes_on_video_id"
    t.index ["workspace_id"], name: "index_notes_on_workspace_id"
  end

  create_table "positions", force: :cascade do |t|
    t.integer "category", default: 1, null: false
    t.datetime "created_at", null: false
    t.integer "dominance", default: 1, null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["parent_id"], name: "index_positions_on_parent_id"
    t.index ["workspace_id", "name"], name: "index_positions_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_positions_on_workspace_id"
  end

  create_table "progresses", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "last_viewed_at"
    t.float "resume_seconds", default: 0.0, null: false
    t.bigint "trackable_id", null: false
    t.string "trackable_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["user_id", "workspace_id", "trackable_type", "trackable_id"], name: "index_progress_unique", unique: true
    t.index ["user_id"], name: "index_progresses_on_user_id"
    t.index ["workspace_id"], name: "index_progresses_on_workspace_id"
  end

  create_table "review_cards", force: :cascade do |t|
    t.string "card_template", default: "basic", null: false
    t.datetime "created_at", null: false
    t.float "difficulty", default: 0.0, null: false
    t.datetime "due_at"
    t.integer "interval_days", default: 0, null: false
    t.integer "lapses", default: 0, null: false
    t.datetime "last_reviewed_at"
    t.uuid "note_id", null: false
    t.integer "reps", default: 0, null: false
    t.float "stability", default: 0.0, null: false
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["due_at"], name: "index_review_cards_on_due_at"
    t.index ["note_id"], name: "index_review_cards_on_note_id"
    t.index ["user_id", "note_id", "card_template"], name: "index_review_cards_on_user_id_and_note_id_and_card_template", unique: true
    t.index ["user_id"], name: "index_review_cards_on_user_id"
  end

  create_table "segments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "end_seconds"
    t.integer "position", default: 0, null: false
    t.float "start_seconds", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "video_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["video_id"], name: "index_segments_on_video_id"
    t.index ["workspace_id"], name: "index_segments_on_workspace_id"
  end

  create_table "shares", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "shareable_id", null: false
    t.string "shareable_type", null: false
    t.bigint "shared_by_id"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.bigint "workspace_id", null: false
    t.index ["shareable_type", "shareable_id", "workspace_id"], name: "index_shares_on_shareable_and_workspace", unique: true
    t.index ["shared_by_id"], name: "index_shares_on_shared_by_id"
    t.index ["token"], name: "index_shares_on_token", unique: true
    t.index ["workspace_id"], name: "index_shares_on_workspace_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["workspace_id", "name"], name: "index_tags_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_tags_on_workspace_id"
  end

  create_table "techniques", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "from_position_id"
    t.integer "kind", default: 0, null: false
    t.string "name", null: false
    t.bigint "to_position_id"
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["from_position_id"], name: "index_techniques_on_from_position_id"
    t.index ["to_position_id"], name: "index_techniques_on_to_position_id"
    t.index ["workspace_id"], name: "index_techniques_on_workspace_id"
  end

  create_table "training_session_notes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "note_id", null: false
    t.bigint "training_session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_training_session_notes_on_note_id"
    t.index ["training_session_id", "note_id"], name: "idx_on_training_session_id_note_id_714730bac1", unique: true
    t.index ["training_session_id"], name: "index_training_session_notes_on_training_session_id"
  end

  create_table "training_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "duration_minutes"
    t.boolean "gi", default: true, null: false
    t.integer "intensity"
    t.integer "kind", default: 0, null: false
    t.string "location"
    t.string "partners"
    t.text "reflection"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["user_id"], name: "index_training_sessions_on_user_id"
    t.index ["workspace_id"], name: "index_training_sessions_on_workspace_id"
  end

  create_table "transcript_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "end_seconds"
    t.integer "position", default: 0, null: false
    t.float "start_seconds", null: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.bigint "video_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["video_id", "start_seconds"], name: "index_transcript_lines_on_video_id_and_start_seconds"
    t.index ["video_id"], name: "index_transcript_lines_on_video_id"
    t.index ["workspace_id"], name: "index_transcript_lines_on_workspace_id"
  end

  create_table "users", force: :cascade do |t|
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

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "videos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "duration_seconds"
    t.integer "source", default: 0, null: false
    t.string "title", null: false
    t.text "transcript"
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id"
    t.uuid "vod_id"
    t.bigint "workspace_id", null: false
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
    t.bigint "uploaded_by_id"
    t.index ["key"], name: "index_vods_on_key", unique: true
    t.index ["upload_expires_at"], name: "index_vods_on_upload_expires_at"
    t.index ["uploaded_by_id"], name: "index_vods_on_uploaded_by_id"
  end

  create_table "workspace_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["user_id", "workspace_id"], name: "index_workspace_memberships_on_user_id_and_workspace_id", unique: true
    t.index ["user_id"], name: "index_workspace_memberships_on_user_id"
    t.index ["workspace_id"], name: "index_workspace_memberships_on_workspace_id"
  end

  create_table "workspaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_workspaces_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "categories", "workspaces"
  add_foreign_key "course_chapters", "courses"
  add_foreign_key "course_chapters", "workspaces"
  add_foreign_key "course_items", "course_chapters"
  add_foreign_key "course_items", "courses"
  add_foreign_key "course_items", "videos"
  add_foreign_key "course_items", "workspaces"
  add_foreign_key "courses", "workspaces"
  add_foreign_key "curriculum_items", "courses"
  add_foreign_key "curriculum_items", "curriculums"
  add_foreign_key "curriculum_items", "workspaces"
  add_foreign_key "curriculums", "workspaces"
  add_foreign_key "folders", "folders", column: "parent_id"
  add_foreign_key "folders", "workspaces"
  add_foreign_key "forks", "users", column: "forked_by_id"
  add_foreign_key "forks", "workspaces", column: "source_workspace_id"
  add_foreign_key "forks", "workspaces", column: "target_workspace_id"
  add_foreign_key "note_positions", "notes"
  add_foreign_key "note_positions", "positions"
  add_foreign_key "note_tags", "notes"
  add_foreign_key "note_tags", "tags"
  add_foreign_key "note_techniques", "notes"
  add_foreign_key "note_techniques", "techniques"
  add_foreign_key "notes", "categories"
  add_foreign_key "notes", "folders"
  add_foreign_key "notes", "users", column: "created_by_id"
  add_foreign_key "notes", "videos"
  add_foreign_key "notes", "workspaces"
  add_foreign_key "positions", "positions", column: "parent_id"
  add_foreign_key "positions", "workspaces"
  add_foreign_key "progresses", "users"
  add_foreign_key "progresses", "workspaces"
  add_foreign_key "review_cards", "notes"
  add_foreign_key "review_cards", "users"
  add_foreign_key "segments", "videos"
  add_foreign_key "segments", "workspaces"
  add_foreign_key "shares", "users", column: "shared_by_id"
  add_foreign_key "shares", "workspaces"
  add_foreign_key "tags", "workspaces"
  add_foreign_key "techniques", "positions", column: "from_position_id"
  add_foreign_key "techniques", "positions", column: "to_position_id"
  add_foreign_key "techniques", "workspaces"
  add_foreign_key "training_session_notes", "notes"
  add_foreign_key "training_session_notes", "training_sessions"
  add_foreign_key "training_sessions", "users"
  add_foreign_key "training_sessions", "workspaces"
  add_foreign_key "transcript_lines", "videos"
  add_foreign_key "transcript_lines", "workspaces"
  add_foreign_key "videos", "users", column: "uploaded_by_id"
  add_foreign_key "videos", "vods"
  add_foreign_key "videos", "workspaces"
  add_foreign_key "vods", "users", column: "uploaded_by_id"
  add_foreign_key "workspace_memberships", "users"
  add_foreign_key "workspace_memberships", "workspaces"
end
