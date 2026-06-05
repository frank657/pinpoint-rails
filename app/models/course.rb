# An ordered set of videos forming one coherent learning unit (docs/decisions/0003).
# Videos are reused via the Course::Item join (a video can live in many courses).
class Course < ApplicationRecord
  acts_as_tenant :workspace
  include Shareable
  extend FriendlyId
  friendly_id :title, use: :scoped, scope: :workspace

  has_many :chapters, -> { order(:position) }, class_name: "Course::Chapter", dependent: :destroy
  has_many :items, -> { order(:position) }, class_name: "Course::Item", dependent: :destroy
  has_many :videos, through: :items
  has_many :curriculum_items, class_name: "Curriculum::Item", dependent: :destroy

  validates :title, presence: true
end
