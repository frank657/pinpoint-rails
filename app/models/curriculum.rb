# An ordered grouping of Courses — the supersequence above a Course (docs/decisions/0003).
class Curriculum < ApplicationRecord
  acts_as_tenant :workspace
  include Shareable
  extend FriendlyId
  friendly_id :title, use: :scoped, scope: :workspace

  has_many :items, -> { order(:position) }, class_name: "Curriculum::Item", dependent: :destroy
  has_many :courses, through: :items

  validates :title, presence: true
end
