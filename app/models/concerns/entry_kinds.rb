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
    system_bet_cancel: SYSTEM_BET_CANCEL = 'system_bet_cancel',
    bonus_change: BONUS_CHANGE = 'bonus_change'
  }.freeze

  FUND_KINDS = [DEPOSIT, WITHDRAW].freeze
  TRADING_KINDS = [WIN, BET, REFUND].freeze
  DEBIT_KINDS = [DEPOSIT, WIN, REFUND, SYSTEM_BET_CANCEL, BONUS_CHANGE].freeze
  CREDIT_KINDS = [
    WITHDRAW,
    BET,
    ROLLBACK,
    SYSTEM_BET_CANCEL,
    BONUS_CHANGE
  ].freeze
  SYSTEM_KINDS = [ROLLBACK, SYSTEM_BET_CANCEL, BONUS_CHANGE].freeze

  included do
    enum kind: KINDS
  end
end
