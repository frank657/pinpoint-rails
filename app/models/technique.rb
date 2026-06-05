# A BJJ technique — a TYPED EDGE between positions (from → to), Axis 2 (docs/decisions/0004).
class Technique < ApplicationRecord
  acts_as_tenant :workspace

  enum :kind, { escape: 0, sweep: 1, pass: 2, submission: 3, transition: 4, takedown: 5 }, prefix: :kind

  belongs_to :from_position, class_name: "Position", optional: true
  belongs_to :to_position, class_name: "Position", optional: true
  has_and_belongs_to_many :notes, join_table: :note_techniques

  validates :name, presence: true
end
