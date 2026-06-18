# Iteration 0008 — convert every remaining bigint primary key (and every FK / polymorphic id
# that references one) to UUID, IN PLACE, preserving data. Locked by ADR 0012.
#
# Strategy (single transaction): snapshot all indexes & FKs on the affected tables; add a fresh
# `gen_random_uuid()` column to each bigint-PK table; add parallel uuid columns for every FK and
# backfill them by joining on the old ids; rewrite polymorphic id values; then swap the columns
# into place, recreate any index dropped with a column, and re-add the foreign keys (now uuid↔uuid).
#
# Framework tables (active_storage_*, action_text_rich_texts) are left untouched — their
# polymorphic record_id is already uuid and they carry no FK into the domain tables.
class ConvertPrimaryKeysToUuid < ActiveRecord::Migration[8.1]
  # bigint-PK tables to convert
  PK_TABLES = %w[
    users workspaces workspace_memberships videos categories tags positions techniques athletes
    progresses forks shares taggings note_categories note_positions note_techniques
    video_athletes video_categories video_positions video_techniques versions
  ].freeze

  # already-uuid-PK tables that still carry bigint FK columns
  UUID_TABLES = %w[notes video_segments vods].freeze

  # [child_table, column, parent_table, not_null]
  FK_COLS = [
    [ "workspace_memberships", "user_id", "users", true ],
    [ "workspace_memberships", "workspace_id", "workspaces", true ],
    [ "athletes", "workspace_id", "workspaces", true ],
    [ "categories", "workspace_id", "workspaces", true ],
    [ "tags", "workspace_id", "workspaces", true ],
    [ "positions", "workspace_id", "workspaces", true ],
    [ "positions", "parent_id", "positions", false ],
    [ "techniques", "workspace_id", "workspaces", true ],
    [ "techniques", "from_position_id", "positions", false ],
    [ "techniques", "to_position_id", "positions", false ],
    [ "notes", "created_by_id", "users", false ],
    [ "notes", "video_id", "videos", false ],
    [ "notes", "workspace_id", "workspaces", true ],
    [ "video_segments", "video_id", "videos", true ],
    [ "video_segments", "workspace_id", "workspaces", true ],
    [ "videos", "uploaded_by_id", "users", false ],
    [ "videos", "workspace_id", "workspaces", true ],
    [ "vods", "uploaded_by_id", "users", false ],
    [ "progresses", "user_id", "users", true ],
    [ "progresses", "workspace_id", "workspaces", true ],
    [ "shares", "shared_by_id", "users", false ],
    [ "shares", "workspace_id", "workspaces", true ],
    [ "taggings", "tag_id", "tags", true ],
    [ "taggings", "workspace_id", "workspaces", true ],
    [ "forks", "forked_by_id", "users", false ],
    [ "forks", "source_workspace_id", "workspaces", false ],
    [ "forks", "target_workspace_id", "workspaces", true ],
    [ "note_categories", "category_id", "categories", true ],
    [ "note_positions", "position_id", "positions", true ],
    [ "note_techniques", "technique_id", "techniques", true ],
    [ "video_athletes", "athlete_id", "athletes", true ],
    [ "video_athletes", "video_id", "videos", true ],
    [ "video_categories", "category_id", "categories", true ],
    [ "video_categories", "video_id", "videos", true ],
    [ "video_positions", "position_id", "positions", true ],
    [ "video_positions", "video_id", "videos", true ],
    [ "video_techniques", "technique_id", "techniques", true ],
    [ "video_techniques", "video_id", "videos", true ]
  ].freeze

  # polymorphic id columns that point at (now-uuid) domain rows. Video is the only non-uuid type
  # that needs its stored value rewritten; Note ids are already uuid strings.
  POLY_STRING = [ %w[taggings taggable_id taggable_type], %w[shares shareable_id shareable_type],
                  %w[forks source_id source_type], %w[forks target_id target_type] ].freeze

  def up
    affected = (PK_TABLES + UUID_TABLES).uniq

    # 1. snapshot indexes (so we can recreate any dropped with a column) and foreign keys.
    saved_indexes = affected.to_h { |t| [ t, connection.indexes(t) ] }
    saved_fks = affected.flat_map { |t| connection.foreign_keys(t) }
    saved_fks.each { |fk| remove_foreign_key fk.from_table, name: fk.name }

    # 2. fresh uuid PK column on every bigint-PK table.
    PK_TABLES.each do |t|
      execute "ALTER TABLE #{t} ADD COLUMN new_uuid_id uuid NOT NULL DEFAULT gen_random_uuid()"
    end

    # 3. parallel uuid column for every FK; backfill by joining on the old id.
    FK_COLS.each do |child, col, parent, _nn|
      execute "ALTER TABLE #{child} ADD COLUMN #{col}_uuid uuid"
      execute "UPDATE #{child} c SET #{col}_uuid = p.new_uuid_id FROM #{parent} p WHERE c.#{col} = p.id"
    end

    # 3b. progresses.trackable_id is a bigint polymorphic id → parallel uuid column.
    execute "ALTER TABLE progresses ADD COLUMN trackable_id_uuid uuid"
    execute "UPDATE progresses pr SET trackable_id_uuid = v.new_uuid_id FROM videos v WHERE pr.trackable_type = 'Video' AND pr.trackable_id = v.id"

    # 4. rewrite string polymorphic ids that point at videos (bigint → new uuid, as text).
    POLY_STRING.each do |table, id_col, type_col|
      execute "UPDATE #{table} t SET #{id_col} = v.new_uuid_id::text FROM videos v WHERE t.#{type_col} = 'Video' AND t.#{id_col} = v.id::text"
    end

    # 4b. PaperTrail history: existing item_ids are stale bigint parses of uuid notes (unusable);
    # truncate so the column can become uuid and record correct ids going forward.
    execute "TRUNCATE versions"

    # 5. swap primary keys.
    PK_TABLES.each do |t|
      execute "ALTER TABLE #{t} DROP CONSTRAINT #{t}_pkey"
      execute "ALTER TABLE #{t} DROP COLUMN id"
      execute "ALTER TABLE #{t} RENAME COLUMN new_uuid_id TO id"
      execute "ALTER TABLE #{t} ADD PRIMARY KEY (id)"
      execute "ALTER TABLE #{t} ALTER COLUMN id SET DEFAULT gen_random_uuid()"
    end

    # 6. swap FK columns into place.
    FK_COLS.each do |child, col, _parent, nn|
      execute "ALTER TABLE #{child} DROP COLUMN #{col}"
      execute "ALTER TABLE #{child} RENAME COLUMN #{col}_uuid TO #{col}"
      execute "ALTER TABLE #{child} ALTER COLUMN #{col} SET NOT NULL" if nn
    end

    # 6b. progresses.trackable_id + polymorphic string columns → uuid type.
    execute "ALTER TABLE progresses DROP COLUMN trackable_id"
    execute "ALTER TABLE progresses RENAME COLUMN trackable_id_uuid TO trackable_id"
    execute "ALTER TABLE progresses ALTER COLUMN trackable_id SET NOT NULL"
    POLY_STRING.each do |table, id_col, _type|
      execute "ALTER TABLE #{table} ALTER COLUMN #{id_col} TYPE uuid USING #{id_col}::uuid"
    end
    execute "ALTER TABLE versions ALTER COLUMN item_id TYPE uuid USING item_id::text::uuid"

    # 7. recreate any index that was dropped along with a converted column.
    saved_indexes.each do |table, idxs|
      idxs.each do |idx|
        next if connection.index_name_exists?(table, idx.name)

        add_index table, idx.columns, name: idx.name, unique: idx.unique,
                  where: idx.where, using: idx.using
      end
    end

    # 8. re-add the foreign keys (uuid ↔ uuid now).
    saved_fks.each do |fk|
      add_foreign_key fk.from_table, fk.to_table, column: fk.column,
                      primary_key: fk.primary_key, on_delete: fk.on_delete, name: fk.name
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "UUID conversion is one-way; restore from a pre-migration dump to roll back."
  end
end
