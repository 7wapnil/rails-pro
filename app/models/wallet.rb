class Wallet < ApplicationRecord
  belongs_to :customer
  has_many :balances
  has_many :entries

  validates :currency, presence: true
end
