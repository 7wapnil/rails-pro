# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class BaseWorker < ApplicationWorker
      sidekiq_options queue: :every_matrix_free_spin_bonuses

      def perform(free_spin_bonus_wallet_id)
        free_spin_bonus_wallet =
          EveryMatrix::FreeSpinBonusWallet.find(free_spin_bonus_wallet_id)

        handler_class.call(
          free_spin_bonus_wallet: free_spin_bonus_wallet
        )
      end

      protected

      def handler_class
        raise NotImplementedError, 'Implement #handler_class method'
      end
    end
  end
end
