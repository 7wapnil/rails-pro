class BalanceEntryRequest < ApplicationRecord
  belongs_to :entry_request
  belongs_to :balance_entry, optional: true

  enum kind: Balance.kinds
  enum status: EntryRequest.statuses

  validates :amount, numericality: true, presence: true
end
