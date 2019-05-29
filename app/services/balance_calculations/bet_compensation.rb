# frozen_string_literal: true

module BalanceCalculations
  class BetCompensation < ApplicationService
    delegate :placement_entry, to: :bet, allow_nil: true
    delegate :real_money_balance_entry,
             :bonus_balance_entry,
             to: :placement_entry, allow_nil: true

    def initialize(entry_request:)
      @entry_request = entry_request
    end

    def call
      return all_real_money if complete_bonus_bet?

      {
        real_money: calculated_real_amount,
        bonus: calculated_bonus_amount
      }
    end

    private

    attr_reader :entry_request

    def all_real_money
      { real_money: entry_request.amount }
    end

    def complete_bonus_bet?
      bet.customer_bonus&.completed?
    end

    def bet
      @bet ||= entry_request.origin
    end

    def calculated_real_amount
      @calculated_real_amount ||= entry_request.amount * ratio
    end

    def ratio
      RatioCalculator.call(
        real_money_amount: real_money_balance_entry&.amount,
        bonus_amount: bonus_balance_entry&.amount
      )
    end

    def calculated_bonus_amount
      entry_request.amount - calculated_real_amount
    end
  end
end
