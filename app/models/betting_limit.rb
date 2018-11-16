class BettingLimit < ApplicationRecord
  belongs_to :customer
  belongs_to :title, optional: true

  validates :customer, presence: true
  validates :customer, uniqueness: { scope: :title }
end
