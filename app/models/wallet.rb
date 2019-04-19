# frozen_string_literal: true

class Wallet < ApplicationRecord
  after_commit :notify_application, on: %i[create update]

  belongs_to :customer
  belongs_to :currency
  has_many :balances
  has_many :balance_entries, through: :balances
  has_many :entries
  has_one :customer_bonus

  has_one :bonus_balance, -> { bonus }, class_name: Balance.name
  has_one :real_money_balance, -> { real_money }, class_name: Balance.name

  validates :amount, numericality: true

  scope :primary, -> { joins(:currency).where(currencies: { primary: true }) }

  delegate :name, :code, to: :currency, prefix: true

  def self.build_default
    new(amount: 0, currency: Currency.build_default)
  end

  def notify_application
    return unless saved_change_to_amount?

    WebSocket::Client.instance.trigger_wallet_update(self)
  end
end
