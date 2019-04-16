class Wallet < ApplicationRecord
  after_commit :notify_application, on: %i[create update]

  belongs_to :customer
  belongs_to :currency
  has_many :balances
  has_many :balance_entries, through: :balances
  has_many :entries
  has_one :customer_bonus

  validates :amount, numericality: true

  scope :primary, -> { joins(:currency).where(currencies: { primary: true }) }

  delegate :name, :code, to: :currency, prefix: true

  def self.build_default
    new(amount: 0, currency: Currency.build_default)
  end

  def bonus_balance
    balances.bonus.last
  end

  def real_money_balance
    balances.real_money.last
  end

  def ratio_with_bonus
    @ratio_with_bonus ||= begin
      bonus_balance_amount = bonus_balance.amount
      real_balance_amount = real_money_balance.amount
      total_balance = bonus_balance_amount + real_balance_amount
      real_balance_amount / total_balance
    end
  end

  def notify_application
    return unless saved_change_to_amount?

    WebSocket::Client.instance.trigger_wallet_update(self)
  end
end
