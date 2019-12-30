# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class ForfeitService < ApplicationService
      def initialize(free_spin_bonus_id:)
        @free_spin_bonus = EveryMatrix::FreeSpinBonus.find(free_spin_bonus_id)
      end

      def call
        process_wallets

        awarded_wallets.count
      end

      private

      attr_reader :free_spin_bonus

      def awarded_wallets
        @awarded_wallets ||= free_spin_bonus.free_spin_bonus_wallets.awarded
      end

      def process_wallets
        awarded_wallets.each do |free_spin_bonus_wallet|
          ForfeitBonusWorker.perform_async(free_spin_bonus_wallet.id)
        end
      end
    end
  end
end
