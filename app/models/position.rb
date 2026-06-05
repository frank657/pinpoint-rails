# A BJJ position (taxonomy node, Axis 2 — docs/decisions/0004). Distinct from free Tags.
class Position < ApplicationRecord
  acts_as_tenant :workspace

  enum :category, { standing: 0, guard: 1, pin: 2, back: 3, leg: 4, turtle: 5 }, prefix: :category
  enum :dominance, { dominant: 0, neutral: 1, inferior: 2 }, prefix: :dominance

  belongs_to :parent, class_name: "Position", optional: true
  has_many :children, class_name: "Position", foreign_key: :parent_id, dependent: :nullify
  has_many :techniques_from, class_name: "Technique", foreign_key: :from_position_id, dependent: :nullify
  has_and_belongs_to_many :notes, join_table: :note_positions

  validates :name, presence: true, uniqueness: { scope: :workspace_id, case_sensitive: false }
end
