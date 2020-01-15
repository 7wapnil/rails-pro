# frozen_string_literal: true

module EveryMatrix
  module Requests
    class ExpireService < ApplicationService
      TIMEOUT_MINUTES = 5

      def call
        pending_wagers.each do |wager|
          process_bonus!(wager)
          wager.game_round.timed_out!
          wager.finished!
        end
      end

      private

      attr_accessor :affected_game_rounds

      def pending_wagers
        EveryMatrix::Wager
          .pending_bonus_loss
          .where('updated_at < ?', TIMEOUT_MINUTES.minutes.ago)
          .includes(:game_round)
          .includes(:customer_bonus)
      end

      def process_bonus!(wager)
        customer_bonus = wager.customer_bonus
        return unless customer_bonus

        lose_bonus!(customer_bonus) if lose_bonus?(customer_bonus)
      end

      def lose_bonus!(customer_bonus)
        ::CustomerBonuses::Deactivate.call(
          bonus: customer_bonus,
          action: ::CustomerBonuses::Deactivate::LOSE
        )
      end

      def lose_bonus?(customer_bonus)
        !customer_bonus.wallet.bonus_balance.positive? &&
          customer_bonus.active? &&
          customer_bonus.rollover_balance.positive? &&
          no_pending_sportsbook_bets?(customer_bonus)
      end

      def no_pending_sportsbook_bets?(customer_bonus)
        return true unless customer_bonus.sportsbook?

        Bet
          .pending
          .where(customer_bonus: customer_bonus)
          .none?
      end
    end
  end
end
