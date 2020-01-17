# frozen_string_literal: true

module EveryMatrix
  module Requests
    class RollbackSettlementService < BaseSettlementService
      def call
        return true unless bonus?

        lose_bonus! if lose_bonus?

        release_pending_wagers! unless lose_bonus?

        update_round_status!

        true
      end

      private

      def update_round_status!
        transaction.game_round.rolled_back!
      end
    end
  end
end
