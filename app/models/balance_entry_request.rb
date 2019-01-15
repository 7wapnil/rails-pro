class BalanceEntryRequest < ApplicationRecord
  belongs_to :entry_request
  belongs_to :balance_entry, optional: true

  enum kind: Balance.kinds

  validates :amount, numericality: true, presence: true

  delegate :status, to: :entry_request
end
