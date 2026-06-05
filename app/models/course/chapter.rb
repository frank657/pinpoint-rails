# An optional section inside a Course that groups its items (docs/decisions/0003).
class Course::Chapter < ApplicationRecord
  self.table_name = "course_chapters"

  acts_as_tenant :workspace
  belongs_to :course
  has_many :items, -> { order(:position) }, class_name: "Course::Item", dependent: :nullify

  validates :title, presence: true
end
