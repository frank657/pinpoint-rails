# Polymorphic join connecting a Tag to any taggable content record (Note, Video, …).
# `taggable_id` is a uuid — every taggable is uuid-keyed since ADR 0012. Workspace-scoped.
class Tagging < ApplicationRecord
  acts_as_tenant :workspace

  belongs_to :tag
  belongs_to :taggable, polymorphic: true

  validates :tag_id, uniqueness: { scope: [ :taggable_type, :taggable_id ] }
end
