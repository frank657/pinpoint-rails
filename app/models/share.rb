# A view-grant on a content object via a token link (docs/decisions/0005). "Private" = no
# Share row. Recipients can view (read-only) and fork; they never mutate the original.
class Share < ApplicationRecord
  acts_as_tenant :workspace

  belongs_to :shareable, polymorphic: true
  belongs_to :shared_by, class_name: "User", optional: true

  enum :visibility, { unlisted: 0, public: 1 }, prefix: :visibility

  has_secure_token :token

  validates :shareable_id, uniqueness: { scope: %i[shareable_type workspace_id] }
end
