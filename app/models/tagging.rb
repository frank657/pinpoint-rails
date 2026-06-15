# Polymorphic join connecting a Tag to any taggable content record (Note, Video, …).
# `taggable_id` is a STRING so it can hold both a Note's UUID and a Video's bigint id
# (iteration 0006a, option (i); same string-id pattern as Share/Fork). Workspace-scoped.
class Tagging < ApplicationRecord
  acts_as_tenant :workspace

  belongs_to :tag
  belongs_to :taggable, polymorphic: true

  validates :tag_id, uniqueness: { scope: [ :taggable_type, :taggable_id ] }
end
