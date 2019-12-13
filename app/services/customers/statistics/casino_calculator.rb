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
          casino_game_count:  wager_games(casino_games).count,
          casino_game_wager:  converted_amount(wager_games(casino_games)),
          casino_game_payout: converted_amount(payout_games(casino_games)),
          live_casino_count:  wager_games(live_casino_games).count,
          live_casino_wager:  converted_amount(wager_games(live_casino_games)),
          live_casino_payout: converted_amount(payout_games(live_casino_games))
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

      def live_casino_games
        @live_casino_games ||= casino_transactions.where(
          "every_matrix_play_items.type = '#{EveryMatrix::Table.name}'"
        )
      end

      def wager_games(source)
        source.where(type: EveryMatrix::Wager.name)
      end

      def payout_games(source)
        source.where(type: EveryMatrix::Result.name)
      end

      def converted_amount(source)
        source.sum(&method(:convert_money))
      end
    end
  end
end
