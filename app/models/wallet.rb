class Wallet < ApplicationRecord
  belongs_to :customer
  belongs_to :currency
  has_many :balances
  has_many :entries

  delegate :name,
           :code,
           to: :currency, prefix: true

  validates :amount,
            numericality: {
              greater_than_or_equal_to: 0,
              message: I18n.t('errors.messages.with_instance.not_negative',
                              instance: I18n.t('entities.wallets', count: 1))
            }

  def self.build_default
    new(amount: 0, currency: Currency.build_default)
  end
end
