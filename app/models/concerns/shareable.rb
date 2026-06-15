# Mixed into forkable/shareable content (Video, Note).
module Shareable
  extend ActiveSupport::Concern

  included do
    has_one :share, as: :shareable, dependent: :destroy
  end

  def shared? = share.present?

  # The Fork attribution where this object is the forked copy (or nil).
  def forked_from_record
    Fork.find_by(target_type: self.class.name, target_id: id.to_s)
  end
end
