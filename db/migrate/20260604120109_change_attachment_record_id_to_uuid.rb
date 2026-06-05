# Our attachable / rich-text owners (Vod, Note) use UUID primary keys, but Active Storage
# and Action Text ship with a bigint polymorphic `record_id`. Make `record_id` a uuid so the
# polymorphic association (and pg_search joins) work. Tables are empty, so the USING
# expression just satisfies the type change. (blob_id stays bigint — blobs are bigint.)
class ChangeAttachmentRecordIdToUuid < ActiveRecord::Migration[8.1]
  def up
    change_column :active_storage_attachments, :record_id, :uuid, using: "gen_random_uuid()"
    change_column :action_text_rich_texts, :record_id, :uuid, using: "gen_random_uuid()"
  end

  def down
    change_column :active_storage_attachments, :record_id, :bigint, using: "0"
    change_column :action_text_rich_texts, :record_id, :bigint, using: "0"
  end
end
