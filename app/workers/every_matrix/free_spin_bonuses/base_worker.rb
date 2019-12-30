# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class BaseWorker < ApplicationWorker
      sidekiq_options queue: :every_matrix_free_spin_bonuses

      def perform(free_spin_bonus_wallet_id)
        @free_spin_bonus_wallet_id = free_spin_bonus_wallet_id

        handler_class.call(
          free_spin_bonus_wallet: free_spin_bonus_wallet
        )
      end

      protected

      attr_reader :free_spin_bonus_wallet_id

      def handler_class
        raise NotImplementedError, 'Implement #handler_class method'
      end

      def free_spin_bonus_wallet
        EveryMatrix::FreeSpinBonusWallet.find(free_spin_bonus_wallet_id)
      end
    end
  end
end
