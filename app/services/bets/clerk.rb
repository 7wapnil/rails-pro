# frozen_string_literal: true

module Bets
  class Clerk < ApplicationService
    BONUS_FIELDS = %i[
      bonus_amount
      converted_bonus_amount
      confiscated_bonus_amount
    ].freeze

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

      debit? ? -converted_bonus_amount.abs : converted_bonus_amount.abs
    end

    def confiscated_money
      return unless bonus_touch? && dismissed?

      debit? ? -confiscated_bonus_amount.abs : confiscated_bonus_amount.abs
    end

    def adjusted_amount
      real_money + (bonus_money || 0)
    end

    def all_money
      debit? ? -origin.amount.abs : origin.amount.abs
    end

    def bonus_touch?
      customer_bonus.present? && !no_affected_bonus_fields?
    end

    def dismissed?
      CustomerBonus::DISMISSED_STATUSES.member?(customer_bonus.status)
    end

    def converted_bonus_amount
      return origin.bonus_amount unless origin.bonus_amount.zero?

      origin.converted_bonus_amount
    end

    def confiscated_bonus_amount
      return origin.bonus_amount unless origin.bonus_amount.zero?

      origin.confiscated_bonus_amount
    end

    def no_affected_bonus_fields?
      origin.slice(*BONUS_FIELDS)
            .values
            .all?(&:zero?)
    end
  end
end
