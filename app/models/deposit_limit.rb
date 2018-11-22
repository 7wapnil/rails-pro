class DepositLimit < ApplicationRecord
  belongs_to :customer
  belongs_to :currency

  NAMED_RANGES = {
    1 => 'day',
    7 => 'week',
    30 => 'month'
  }.freeze

  validates :customer, :value, :range, presence: true
  validates :customer, uniqueness: true
end
