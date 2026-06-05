# Ordered membership of a Course in a Curriculum (docs/decisions/0003).
class Curriculum::Item < ApplicationRecord
  self.table_name = "curriculum_items"

  acts_as_tenant :workspace
  belongs_to :curriculum
  belongs_to :course

  validates :course_id, uniqueness: { scope: :curriculum_id }
end
