class CustomerNote < ApplicationRecord
  default_scope { order(created_at: :desc) }

  belongs_to :customer
  belongs_to :user

  validates :content, presence: true

  delegate :full_name, to: :user, prefix: true
end
