# frozen_string_literal: true

module Customers
  module Statistics
    class CasinoCalculator < Calculator
      EM_TABLE = 'every_matrix_play_items'

      def initialize(customer)
        @customer = customer
      end

      def call
        {
          casino_game_count: casino_games.count,
          casino_game_wager: casino_game_wager,
          casino_game_payout: casino_game_payout,
          live_casino_count: live_casino_games.count,
          live_casino_wager: live_casino_wager,
          live_casino_payout: live_casino_payout
        }
      end

      private

      attr_reader :customer

      def casino_transactions
        @casino_transactions ||= customer.every_matrix_transactions
                                         .joins(:play_item)
                                         .where(updated_at_clause(EM_TABLE))
      end

      def casino_games
        @casino_games ||= casino_transactions.where(
          "every_matrix_play_items.type = '#{EveryMatrix::Game.name}'"
        )
      end

      def casino_game_wager
        casino_games.where(type: EveryMatrix::Wager.name)
                    .sum(&method(:convert_money))
      end

      def casino_game_payout
        casino_games.where(type: EveryMatrix::Result.name)
                    .sum(&method(:convert_money))
      end

      def live_casino_games
        @live_casino_games ||= casino_transactions.where(
          "every_matrix_play_items.type = '#{EveryMatrix::Table.name}'"
        )
      end

      def live_casino_wager
        live_casino_games.where(type: EveryMatrix::Wager.name)
                         .sum(&method(:convert_money))
      end

      def live_casino_payout
        live_casino_games.where(type: EveryMatrix::Result.name)
                         .sum(&method(:convert_money))
      end
    end
  end
end
