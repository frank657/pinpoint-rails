# A person featured in a video — a coach or athlete (taxonomy axis, ADR 0004 — kept separate
# from free Tags and the Position/Technique graph). Role-agnostic: in BJJ the people in an
# instructional are athletes either way. Unique per workspace.
class Athlete < ApplicationRecord
  acts_as_tenant :workspace

  has_and_belongs_to_many :videos, join_table: :video_athletes
  has_one_attached :avatar

  validates :name, presence: true, uniqueness: { scope: :workspace_id, case_sensitive: false }

  # Find-or-create athletes by name within the current workspace (case-insensitive de-dup).
  def self.for_names(names)
    Array(names).map { |n| n.to_s.strip }.reject(&:blank?).uniq { |n| n.downcase }.map do |name|
      where("lower(name) = ?", name.downcase).first_or_create!(name: name)
    end
  end

  # Up-to-two-letter monogram used when there's no avatar image (UI falls back to a coloured
  # initials badge — iteration 0007 scope addition).
  def initials
    name.to_s.strip.split(/\s+/).map { |w| w[0] }.first(2).join.upcase
  end

  # A deterministic hue (0–359) derived from the name, so an athlete's fallback badge keeps the
  # same colour across the app. Mirrors the mockup's char-sum → hsl() avatar.
  def avatar_hue
    name.to_s.chars.sum(&:ord) % 360
  end
end
