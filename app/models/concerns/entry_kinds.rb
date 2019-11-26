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
    bonus_change: BONUS_CHANGE = 'bonus_change',
    em_wager: EVERY_MATRIX_WAGER = 'em_wager',
    em_result: EVERY_MATRIX_RESULT = 'em_result',
    em_rollback: EVERY_MATRIX_ROLLBACK = 'em_rollback'
  }.freeze

  INCOME_ENTRY_KINDS = [DEPOSIT, BONUS_CHANGE].freeze
  FUND_KINDS = [DEPOSIT, WITHDRAW].freeze
  TRADING_KINDS = [WIN, BET, REFUND,
                   EVERY_MATRIX_WAGER,
                   EVERY_MATRIX_RESULT,
                   EVERY_MATRIX_ROLLBACK].freeze
  DEBIT_KINDS = [
    DEPOSIT,
    WIN,
    REFUND,
    ROLLBACK,
    SYSTEM_BET_CANCEL,
    MANUAL_BET_CANCEL,
    BONUS_CONVERSION,
    BONUS_CHANGE,
    EVERY_MATRIX_RESULT,
    EVERY_MATRIX_ROLLBACK
  ].freeze
  CREDIT_KINDS = [
    WITHDRAW,
    BET,
    ROLLBACK,
    SYSTEM_BET_CANCEL,
    MANUAL_BET_CANCEL,
    BONUS_CHANGE,
    EVERY_MATRIX_WAGER
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
