# frozen_string_literal: true

module CustomerBonuses
  class RollbackBonusRolloverService < ApplicationService
    def initialize(bet:)
      @bet = bet
    end

    def call
      return unless eligible?

      tag_bet_rollover!
      recalculate_rollover!
    end

    private

    attr_reader :bet

    delegate :customer_bonus, to: :bet

    def eligible?
      customer_bonus && bet.counted_towards_rollover?
    end

    def tag_bet_rollover!
      bet.update!(counted_towards_rollover: false)
    end

    def recalculate_rollover!
      customer_bonus.rollover_balance += bet_rollover_amount
      customer_bonus.save!
    end

    def bet_rollover_amount
      [customer_bonus.max_rollover_per_bet, bet.amount].min
    end
  end
end
