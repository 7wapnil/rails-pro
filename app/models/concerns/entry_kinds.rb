module EntryKinds
  extend ActiveSupport::Concern

  KINDS = {
    deposit: 0,
    win: 1,
    withdraw: 3,
    bet: 4
  }.freeze

  FUND_KINDS = KINDS.slice(:deposit, :withdraw)

  TRADING_KINDS = KINDS.slice(:win, :bet)

  DEBIT_KINDS = KINDS.slice(:deposit, :win)

  CREDIT_KINDS = KINDS.slice(:withdraw, :bet)

  included do
    enum kind: KINDS
  end
end
