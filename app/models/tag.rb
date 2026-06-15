# Free-form tag (taxonomy axis — kept separate from the curated Position/Technique taxonomy,
# docs/decisions/0004). Unique per workspace. Applied polymorphically to Notes and Videos via
# `taggings` (iteration 0006a).
class Tag < ApplicationRecord
  acts_as_tenant :workspace

  has_many :taggings, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :workspace_id, case_sensitive: false }

  # Find-or-create tags by name within the current workspace (case-insensitive de-dup).
  def self.for_names(names)
    Array(names).map { |n| n.to_s.strip }.reject(&:blank?).uniq { |n| n.downcase }.map do |name|
      where("lower(name) = ?", name.downcase).first_or_create!(name: name)
    end
  end

  # How many records (of any type) this tag is applied to.
  def usage_count = taggings.count

  # Move this tag's taggings onto `target` (de-duplicating), then delete this tag.
  # Returns the surviving target tag. No-op when merging into itself.
  def merge_into!(target)
    return self if target == self

    transaction do
      taggings.find_each do |tagging|
        if target.taggings.exists?(taggable_type: tagging.taggable_type, taggable_id: tagging.taggable_id)
          tagging.destroy!
        else
          tagging.update!(tag: target)
        end
      end
      destroy!
    end
    target
  end
end
