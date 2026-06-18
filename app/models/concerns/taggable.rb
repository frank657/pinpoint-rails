# Mixed into content models that can carry free-form tags (Note, Video). Provides the
# polymorphic tag association plus a `tag_names=` setter that find-or-creates tags by name.
# `taggable_id` is uuid for every taggable since ADR 0012.
module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings
  end

  # Replace this record's tags from a list of names (case-insensitive find-or-create).
  def tag_names=(names)
    self.tags = Tag.for_names(names)
  end

  def tag_names
    tags.map(&:name)
  end
end
