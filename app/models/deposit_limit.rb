class DepositLimit < ApplicationRecord
  belongs_to :customer
  belongs_to :currency

  NAMED_RANGES = {
    1 => 'day',
    7 => 'week',
    30 => 'month'
  }.freeze

  delegate :code, to: :currency, prefix: true

  validates :customer, :value, :range, presence: true
  validates :customer, uniqueness: true

  def range_name
    return NAMED_RANGES[range] if NAMED_RANGES.key?(range)

    I18n.t('days', days: range)
  end

  def loggable_attributes
    { currency_code: currency_code,
      range: range_name,
      value: value }
  end
end
