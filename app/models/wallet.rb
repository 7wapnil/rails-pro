class Wallet < ApplicationRecord
  belongs_to :customer

  validates :currency, presence: true
end
