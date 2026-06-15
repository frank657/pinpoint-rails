# A person featured in a video — a coach or athlete (taxonomy axis, ADR 0004 — kept separate
# from free Tags and the Position/Technique graph). Role-agnostic: in BJJ the people in an
# instructional are athletes either way. Unique per workspace.
class Athlete < ApplicationRecord
  acts_as_tenant :workspace

  has_and_belongs_to_many :videos, join_table: :video_athletes

  validates :name, presence: true, uniqueness: { scope: :workspace_id, case_sensitive: false }

  # Find-or-create athletes by name within the current workspace (case-insensitive de-dup).
  def self.for_names(names)
    Array(names).map { |n| n.to_s.strip }.reject(&:blank?).uniq { |n| n.downcase }.map do |name|
      where("lower(name) = ?", name.downcase).first_or_create!(name: name)
    end
  end
end
