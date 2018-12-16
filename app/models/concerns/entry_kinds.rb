module EntryKinds
  extend ActiveSupport::Concern

  KINDS = {
    deposit:  DEPOSIT  = 'deposit',
    win:      WIN      = 'win',
    withdraw: WITHDRAW = 'withdraw',
    bet:      BET      = 'bet',
    refund:   REFUND   = 'refund'
  }.freeze

  FUND_KINDS = KINDS.slice(:deposit, :withdraw)

  TRADING_KINDS = KINDS.slice(:win, :bet, :refund)

  DEBIT_KINDS = KINDS.slice(:deposit, :win, :refund)

  CREDIT_KINDS = KINDS.slice(:withdraw, :bet)

  included do
    enum kind: KINDS
  end
end
