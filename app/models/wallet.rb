class Wallet < ApplicationRecord
  belongs_to :customer
  has_many :balances
  has_many :transactions

  validates :currency, presence: true
end
