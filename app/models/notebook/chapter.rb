# An optional section inside a Notebook that groups its items (ADR 0010).
class Notebook::Chapter < ApplicationRecord
  self.table_name = "notebook_chapters"

  acts_as_tenant :workspace
  belongs_to :notebook
  has_many :items, -> { order(:position) }, class_name: "Notebook::Item", foreign_key: :notebook_chapter_id, dependent: :nullify

  validates :title, presence: true
end
