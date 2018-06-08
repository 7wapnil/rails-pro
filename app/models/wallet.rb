class Wallet < ApplicationRecord
  belongs_to :customer
  belongs_to :currency
  has_many :balances
  has_many :entries

  delegate :name,
           :code,
           to: :currency, prefix: true
end
