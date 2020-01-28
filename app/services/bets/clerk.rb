# frozen_string_literal: true

module Bets
  class Clerk < ApplicationService
    delegate :customer_bonus, to: :bet, allow_nil: true

    def initialize(bet:, origin:, debit: false)
      @bet = bet
      @origin = origin
      @debit = debit
    end

    def call
      balance_transitions.compact
                         .merge(amount: adjusted_amount)
    end

    private

    attr_reader :bet, :origin, :debit
    alias_method :debit?, :debit

    def balance_transitions
      {
        real_money_amount: real_money,
        bonus_amount: bonus_money,
        confiscated_bonus_amount: confiscated_money,
        converted_bonus_amount: converted_money
      }
    end

    def real_money
      return all_money unless bonus_touch?
      return all_money if customer_bonus.completed?

      debit? ? -origin.real_money_amount.abs : origin.real_money_amount.abs
    end

    def bonus_money
      return unless bonus_touch? && customer_bonus.active?

      debit? ? -origin.bonus_amount.abs : origin.bonus_amount.abs
    end

    def converted_money
      return unless bonus_touch? && customer_bonus.completed?

      debit? ? -origin.bonus_amount.abs : origin.bonus_amount.abs
    end

    def confiscated_money
      return unless bonus_touch? && dismissed?

      debit? ? -origin.bonus_amount.abs : origin.bonus_amount.abs
    end

    def adjusted_amount
      real_money + (bonus_money || 0)
    end

    def all_money
      debit? ? -origin.amount.abs : origin.amount.abs
    end

    def bonus_touch?
      customer_bonus.present? && !origin.bonus_amount.zero?
    end

    def dismissed?
      CustomerBonus::DISMISSED_STATUSES.member?(customer_bonus.status)
    end
  end
end
