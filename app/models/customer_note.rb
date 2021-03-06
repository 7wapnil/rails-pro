class CustomerNote < ApplicationRecord
  include Loggable

  default_scope { order(created_at: :desc) }

  acts_as_paranoid

  belongs_to :customer
  belongs_to :user

  validates :content, presence: true

  delegate :full_name, to: :user, prefix: true

  def loggable_attributes
    { id: id,
      content: content }
  end
end
