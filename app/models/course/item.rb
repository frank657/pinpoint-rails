# Ordered membership of a Video in a Course (optionally within a Chapter). The same Video
# can belong to many courses with independent ordering (docs/decisions/0003).
class Course::Item < ApplicationRecord
  self.table_name = "course_items"

  acts_as_tenant :workspace
  belongs_to :course
  belongs_to :video
  belongs_to :chapter, class_name: "Course::Chapter", foreign_key: :course_chapter_id, optional: true

  validates :video_id, uniqueness: { scope: :course_id }
end
