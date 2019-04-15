# frozen_string_literal: true

module EntryKinds
  extend ActiveSupport::Concern

  KINDS = {
    deposit: DEPOSIT = 'deposit',
    win: WIN = 'win',
    withdraw: WITHDRAW = 'withdraw',
    bet: BET = 'bet',
    refund: REFUND = 'refund',
    rollback: ROLLBACK = 'rollback',
    system_bet_cancel: SYSTEM_BET_CANCEL = 'system_bet_cancel'
  }.freeze

  FUND_KINDS = KINDS.slice(:deposit, :withdraw)
  TRADING_KINDS = KINDS.slice(:win, :bet, :refund)
  DEBIT_KINDS = KINDS.slice(:deposit, :win, :refund, :system_bet_cancel)
  CREDIT_KINDS = KINDS.slice(:withdraw, :bet, :rollback, :system_bet_cancel)

  included do
    enum kind: KINDS
  end
end
