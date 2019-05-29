# frozen_string_literal: true

class BalanceEntry < ApplicationRecord
  belongs_to :balance
  belongs_to :entry

  has_one :customer_bonus, inverse_of: :balance_entry

  validates :amount, presence: true

  # scope :real_money
  # scope :bonus
  Balance.kinds.keys.each do |kind|
    scope kind.to_sym, -> { joins(:balance).where(balances: { kind: kind }) }
  end
end
