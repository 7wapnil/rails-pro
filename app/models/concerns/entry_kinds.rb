module EntryKinds
  extend ActiveSupport::Concern

  KINDS = {
    deposit: 0,
    win: 1,
    withdraw: 3,
    bet: 4,
    refund: 5
  }.freeze

  FUND_KINDS = KINDS.slice(:deposit, :withdraw)

  TRADING_KINDS = KINDS.slice(:win, :bet, :refund)

  DEBIT_KINDS = KINDS.slice(:deposit, :win, :refund)

  CREDIT_KINDS = KINDS.slice(:withdraw, :bet)

  included do
    enum kind: KINDS
  end
end
