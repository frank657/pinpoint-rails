# A logged training session (Axis 3 — per user + workspace, docs/decisions/0004). Links to
# the notes/techniques studied, connecting instructional content to mat time.
class TrainingSession < ApplicationRecord
  acts_as_tenant :workspace
  belongs_to :user

  enum :kind, { drill: 0, roll: 1, positional: 2, class_session: 3, competition: 4 }

  has_and_belongs_to_many :notes, join_table: :training_session_notes

  validates :date, presence: true

  scope :recent, -> { order(date: :desc) }
end
