class DepositLimit < ApplicationRecord
  belongs_to :customer
  belongs_to :currency

  NAMED_RANGES = {
    1 => I18n.t('entities.activities.days', count: 1),
    7 => I18n.t('entities.activities.weeks', count: 1),
    30 => I18n.t('entities.activities.months', count: 1)
  }.freeze

  validates :customer, :value, :range, presence: true
  validates :customer, uniqueness: true
end
