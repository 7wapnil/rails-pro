class BalanceEntryRequest < ApplicationRecord
  belongs_to :entry_request
  belongs_to :balance_entry, optional: true
  has_one :balance, through: :balance_entry
  enum kind: Balance.kinds

  validates :amount, numericality: true, presence: true
  validates_uniqueness_of :entry_request_id, scope: :kind, message: 'entry
 request already has balance entry request with this kind.'
  delegate :status, to: :entry_request
end
