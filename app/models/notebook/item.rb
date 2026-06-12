# Ordered membership of a Video in a Notebook (optionally within a Chapter). The same Video
# can belong to many notebooks with independent ordering (ADR 0010, supersedes 0003).
class Notebook::Item < ApplicationRecord
  self.table_name = "notebook_items"

  acts_as_tenant :workspace
  belongs_to :notebook
  belongs_to :video
  belongs_to :chapter, class_name: "Notebook::Chapter", foreign_key: :notebook_chapter_id, optional: true

  validates :video_id, uniqueness: { scope: :notebook_id }
end
