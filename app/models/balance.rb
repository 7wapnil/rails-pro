# frozen_string_literal: true

class Balance < ApplicationRecord
  belongs_to :wallet
  has_many :balance_entries

  validates :kind, presence: true
  validates :amount, numericality: true

  delegate :currency_code, to: :wallet

  enum kind: {
    real_money: REAL_MONEY = 'real_money',
    bonus:      BONUS      = 'bonus'
  }
end
