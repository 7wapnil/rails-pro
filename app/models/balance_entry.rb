class BalanceEntry < ApplicationRecord
  belongs_to :balance
  belongs_to :entry

  validates :amount, presence: true

  def auditable?
    false
  end
end
