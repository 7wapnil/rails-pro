class CustomerNote < ApplicationRecord
  belongs_to :customer
  belongs_to :user

  validates :content, presence: true
end
