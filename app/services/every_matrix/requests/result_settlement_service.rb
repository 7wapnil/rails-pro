# frozen_string_literal: true

module EveryMatrix
  module Requests
    class ResultSettlementService < BaseSettlementService
      def call
        return true unless bonus?

        lose_bonus! if lose_bonus?

        release_pending_wagers! unless lose_bonus?

        update_round_status!

        true
      end

      private

      def update_round_status!
        return transaction.game_round.lost! if transaction.amount.zero?

        transaction.game_round.won!
      end
    end
  end
end
