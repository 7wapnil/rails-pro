# frozen_string_literal: true

class Balance < ApplicationRecord
  belongs_to :wallet
  has_many :balance_entries

  validates :kind, presence: true

  validates :amount,
            numericality: {
              greater_than_or_equal_to: 0,
              message: I18n.t('errors.messages.with_instance.not_negative',
                              instance: I18n.t('entities.balance'))
            }

  enum kind: {
    real_money: REAL_MONEY = 'real_money',
    bonus:      BONUS      = 'bonus'
  }
end
