class Wallet < ApplicationRecord
  belongs_to :customer
  has_many :balances
  has_many :entries

  enum currency: {
    euro: 0
  }

  validates :currency, presence: true
end
