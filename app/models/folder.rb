# Note organization — a nestable folder (docs/decisions/0003). Orthogonal to courses.
class Folder < ApplicationRecord
  acts_as_tenant :workspace
  include Shareable

  belongs_to :parent, class_name: "Folder", optional: true
  has_many :children, -> { order(:position) }, class_name: "Folder", foreign_key: :parent_id, dependent: :destroy
  has_many :notes, dependent: :nullify

  validates :name, presence: true
  validate :parent_not_self

  private

  def parent_not_self
    errors.add(:parent, "can't be itself") if parent_id.present? && parent_id == id
  end
end
