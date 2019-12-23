# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class RetryHandler < BaseRequestHandler
      delegate :user_created_with_error?,
               :awarded_with_error?,
               :forfeited_with_error?,
               to: :free_spin_bonus_wallet

      def call
        return retry_award if awarded_with_error? || user_created_with_error?

        retry_forfeit if forfeited_with_error?
      end

      private

      def retry_award
        AwardBonusHandler.call(free_spin_bonus_wallet: free_spin_bonus_wallet)
      end

      def retry_forfeit
        ForfeitBonusHandler.call(free_spin_bonus_wallet: free_spin_bonus_wallet)
      end
    end
  end
end
