# frozen_string_literal: true

class Wallet < ApplicationRecord
  after_commit :notify_application, on: %i[create update]

  belongs_to :customer
  belongs_to :currency
  has_many :entries

  has_one :crypto_address, dependent: :destroy
  has_many :customer_bonuses
  has_one :customer_bonus, -> { reorder('activated_at DESC NULLS LAST') }
  has_one :active_bonus, -> { active }, class_name: CustomerBonus.name
  has_one :initial_customer_bonus,
          -> { initial.reorder('created_at DESC') },
          class_name: CustomerBonus.name

  scope :primary, -> { joins(:currency).where(currencies: { primary: true }) }

  delegate :name, :code, to: :currency, prefix: true

  def self.fiat
    joins(:currency).where(currencies: { kind: Currency::FIAT })
  end

  def self.crypto
    joins(:currency).where(currencies: { kind: Currency::CRYPTO })
  end

  def self.build_default
    new(amount: 0, currency: Currency.build_default)
  end

  def notify_application
    return unless saved_change_to_amount?

    WebSocket::Client.instance.trigger_wallet_update(self)
  end

  def negative_balance?
    real_money_balance.negative? || bonus_balance.negative?
  end

  def to_s
    "#{currency} Wallet"
  end

  def with_money?
    amount.positive? ||
      real_money_balance.positive? ||
      bonus_balance.positive?
  end
end
