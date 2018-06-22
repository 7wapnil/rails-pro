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
    real_money: 0,
    bonus: 1
  }
end
