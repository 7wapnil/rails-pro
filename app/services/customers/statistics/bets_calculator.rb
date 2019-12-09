# frozen_string_literal: true

module Customers
  module Statistics
    class BetsCalculator < Calculator
      def initialize(customer)
        @customer = customer
      end

      def call
        {
          prematch_bet_count: prematch_bets.length,
          prematch_wager: prematch_wager,
          prematch_payout: prematch_payout,
          live_bet_count: live_bets.length,
          live_sports_wager: live_sports_wager,
          live_sports_payout: live_sports_payout
        }
      end

      private

      attr_reader :customer

      def prematch_bets
        @prematch_bets ||= settled_bets
                           .having('bets.created_at <= MIN(events.start_at)')
      end

      def settled_bets
        @settled_bets ||= customer.bets
                                  .joins(:currency, bet_legs: :event)
                                  .group('bets.id')
                                  .where(status: Bet::SETTLED_STATUSES_MASK)
                                  .where(updated_at_clause('bets'))
      end

      def prematch_wager
        prematch_bets.find_each(batch_size: BATCH_SIZE)
                     .sum(&method(:convert_money))
      end

      def prematch_payout
        prematch_bets.won
                     .find_each(batch_size: BATCH_SIZE)
                     .sum { |bet| convert_money(bet, :win_amount) }
      end

      def live_bets
        @live_bets ||= settled_bets
                       .having('bets.created_at > MIN(events.start_at)')
      end

      def live_sports_wager
        live_bets.find_each(batch_size: BATCH_SIZE)
                 .sum(&method(:convert_money))
      end

      def live_sports_payout
        live_bets.won
                 .find_each(batch_size: BATCH_SIZE)
                 .sum { |bet| convert_money(bet, :win_amount) }
      end
    end
  end
end
