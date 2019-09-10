# frozen_string_literal: true

class BalanceEntry < ApplicationRecord
  after_commit :update_summary, on: :create, unless: :bet_entry?

  belongs_to :balance
  belongs_to :entry

  has_one :customer_bonus, inverse_of: :balance_entry
  has_one :currency, through: :entry
  has_one :balance_entry_request, inverse_of: :balance_entry

  validates :amount, presence: true

  delegate :currency, to: :balance

  # scope :real_money
  # scope :bonus
  Balance.kinds.keys.each do |kind|
    scope kind.to_sym, -> { joins(:balance).where(balances: { kind: kind }) }
  end

  private

  def update_summary
    Customers::Summaries::BalanceUpdateWorker.perform_async(Date.current, id)
  end

  def bet_entry?
    entry&.bet?
  end
end
