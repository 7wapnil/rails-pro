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
    manual_bet_cancel: MANUAL_BET_CANCEL = 'manual_bet_cancel',
    bonus_conversion: BONUS_CONVERSION = 'bonus_conversion',
    bonus_change: BONUS_CHANGE = 'bonus_change'
  }.freeze

  INCOME_ENTRY_KINDS = [DEPOSIT, BONUS_CHANGE].freeze
  FUND_KINDS = [DEPOSIT, WITHDRAW].freeze
  TRADING_KINDS = [WIN, BET, REFUND].freeze
  DEBIT_KINDS = [
    DEPOSIT,
    WIN,
    REFUND,
    SYSTEM_BET_CANCEL,
    MANUAL_BET_CANCEL,
    BONUS_CONVERSION,
    BONUS_CHANGE
  ].freeze
  CREDIT_KINDS = [
    WITHDRAW,
    BET,
    ROLLBACK,
    SYSTEM_BET_CANCEL,
    MANUAL_BET_CANCEL,
    BONUS_CHANGE
  ].freeze
  DELAYED_CONFIRMATION_KINDS = [WITHDRAW, BET].freeze
  ALLOWED_NEGATIVE_BALANCE_KINDS = [
    BONUS_CHANGE,
    DEPOSIT,
    REFUND,
    ROLLBACK,
    SYSTEM_BET_CANCEL,
    MANUAL_BET_CANCEL,
    WIN
  ].freeze

  included do
    enum kind: KINDS
  end
end
