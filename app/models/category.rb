# User-defined note category (taxonomy axis — docs/decisions/0004). Unique per workspace.
class Category < ApplicationRecord
  acts_as_tenant :workspace

  has_many :notes, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :workspace_id, case_sensitive: false }
end
