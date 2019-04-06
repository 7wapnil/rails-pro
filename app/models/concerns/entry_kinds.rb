# frozen_string_literal: true

module EntryKinds
  extend ActiveSupport::Concern

  KINDS = {
    deposit:  DEPOSIT  = 'deposit',
    win:      WIN      = 'win',
    withdraw: WITHDRAW = 'withdraw',
    bet:      BET      = 'bet',
    refund:   REFUND   = 'refund',
    rollback: ROLLBACK = 'rollback'
  }.freeze

  FUND_KINDS = KINDS.slice(:deposit, :withdraw)
  TRADING_KINDS = KINDS.slice(:win, :bet, :refund)
  DEBIT_KINDS = KINDS.slice(:deposit, :win, :refund)
  CREDIT_KINDS = KINDS.slice(:withdraw, :bet, :rollback)

  included do
    enum kind: KINDS
  end
end
