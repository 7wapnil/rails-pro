# frozen_string_literal: true

module EntryKinds
  extend ActiveSupport::Concern

  KINDS = {
    deposit: DEPOSIT = 'deposit',
    win: WIN = 'win',
    withdraw: WITHDRAW = 'withdraw',
    confiscation: CONFISCATION = 'confiscation',
    bet: BET = 'bet',
    refund: REFUND = 'refund',
    rollback: ROLLBACK = 'rollback',
    system_bet_cancel: SYSTEM_BET_CANCEL = 'system_bet_cancel',
    manual_bet_cancel: MANUAL_BET_CANCEL = 'manual_bet_cancel',
    manual_bet_placement: MANUAL_BET_PLACEMENT = 'manual_bet_placement',
    bonus_conversion: BONUS_CONVERSION = 'bonus_conversion',
    bonus_change: BONUS_CHANGE = 'bonus_change',
    bonus_expiration: BONUS_EXPIRATION = 'bonus_expiration',
    bonus_cancellation: BONUS_CANCELLATION = 'bonus_cancellation',
    bonus_loss: BONUS_LOSS = 'bonus_loss',
    em_wager: EVERY_MATRIX_WAGER = 'em_wager',
    em_result: EVERY_MATRIX_RESULT = 'em_result',
    em_rollback: EVERY_MATRIX_ROLLBACK = 'em_rollback'
  }.freeze

  INCOME_ENTRY_KINDS = [DEPOSIT, BONUS_CHANGE].freeze
  FUND_KINDS = [DEPOSIT, WITHDRAW, CONFISCATION].freeze
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
    MANUAL_BET_PLACEMENT,
    BONUS_CONVERSION,
    BONUS_CHANGE,
    BONUS_LOSS,
    BONUS_EXPIRATION,
    BONUS_CANCELLATION,
    EVERY_MATRIX_RESULT,
    EVERY_MATRIX_ROLLBACK
  ].freeze
  CREDIT_KINDS = [
    WITHDRAW,
    CONFISCATION,
    BET,
    ROLLBACK,
    SYSTEM_BET_CANCEL,
    MANUAL_BET_CANCEL,
    MANUAL_BET_PLACEMENT,
    BONUS_CHANGE,
    BONUS_EXPIRATION,
    BONUS_CANCELLATION,
    BONUS_LOSS,
    EVERY_MATRIX_WAGER
  ].freeze
  DELAYED_CONFIRMATION_KINDS = [WITHDRAW, BET].freeze
  ALLOWED_NEGATIVE_BALANCE_KINDS = [
    CONFISCATION,
    BONUS_CHANGE,
    BONUS_EXPIRATION,
    BONUS_CANCELLATION,
    BONUS_LOSS,
    DEPOSIT,
    REFUND,
    ROLLBACK,
    SYSTEM_BET_CANCEL,
    MANUAL_BET_CANCEL,
    MANUAL_BET_PLACEMENT,
    WIN
  ].freeze

  included do
    enum kind: KINDS
  end
end
