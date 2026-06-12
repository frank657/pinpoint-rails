# A Notebook — a study unit: an ordered set of Videos grouped into Chapters, with the user's
# Notes living on those videos (ADR 0010, supersedes 0003). Workspace-scoped Axis-1 content:
# shared & forkable; media shared by reference; per-user state never copied (0004, 0005).
class Notebook < ApplicationRecord
  acts_as_tenant :workspace
  include Shareable
  extend FriendlyId
  friendly_id :title, use: :scoped, scope: :workspace

  has_many :chapters, -> { order(:position) }, class_name: "Notebook::Chapter", dependent: :destroy
  has_many :items, -> { order(:position) }, class_name: "Notebook::Item", dependent: :destroy
  has_many :videos, through: :items

  validates :title, presence: true
end
