class Wallet < ApplicationRecord
  belongs_to :customer
  has_many :balances

  validates :currency, presence: true
end
