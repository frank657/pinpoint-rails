# Free-form note tag (taxonomy axis — kept separate from the curated Position/Technique
# taxonomy, docs/decisions/0004). Unique per workspace.
class Tag < ApplicationRecord
  acts_as_tenant :workspace

  has_and_belongs_to_many :notes, join_table: :note_tags

  validates :name, presence: true, uniqueness: { scope: :workspace_id, case_sensitive: false }

  # Find-or-create tags by name within the current workspace (case-insensitive de-dup).
  def self.for_names(names)
    Array(names).map { |n| n.to_s.strip }.reject(&:blank?).uniq { |n| n.downcase }.map do |name|
      where("lower(name) = ?", name.downcase).first_or_create!(name: name)
    end
  end
end
