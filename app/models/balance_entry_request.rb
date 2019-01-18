class BalanceEntryRequest < ApplicationRecord
  belongs_to :entry_request
  belongs_to :balance_entry, optional: true
  has_one :balance, through: :balance_entry
  enum kind: Balance.kinds

  validates :amount, numericality: true, presence: true
  validates :entry_request_id,
            uniqueness: {
              scope: :kind,
              message: I18n.t('errors.messages.balance_request_uniqueness')
            }
end
