# User-defined note category (taxonomy axis — docs/decisions/0004). Unique per workspace.
class Category < ApplicationRecord
  acts_as_tenant :workspace

  has_and_belongs_to_many :notes, join_table: :note_categories

  validates :name, presence: true, uniqueness: { scope: :workspace_id, case_sensitive: false }

  # How many notes are filed under this category.
  def usage_count = notes.count

  # Move this category's notes onto `target`, then delete this category. Returns the target.
  def merge_into!(target)
    return self if target == self

    transaction do
      notes.find_each { |note| note.categories = (note.categories - [ self ] + [ target ]).uniq }
      destroy!
    end
    target
  end
end
