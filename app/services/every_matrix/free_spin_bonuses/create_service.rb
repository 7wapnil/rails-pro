# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class CreateService < ApplicationService
      def initialize(bonus_params:, play_item_ids:, customers_csv:)
        @bonus_params = bonus_params
        @play_item_ids = play_item_ids
        @customers_csv = customers_csv
      end

      def call
        create_free_spin_bonus!
        create_free_spin_bonus_play_items!
        create_free_spin_bonus_wallets!
        request_bonus_award

        free_spin_bonus_wallet_ids.count
      end

      private

      attr_reader :bonus_params, :play_item_ids,
                  :customers_csv, :free_spin_bonus,
                  :free_spin_bonus_wallet_ids

      def create_free_spin_bonus!
        @free_spin_bonus = EveryMatrix::FreeSpinBonus.create!(bonus_params)
      end

      def create_free_spin_bonus_play_items!
        play_item_ids.each do |play_item_id|
          EveryMatrix::FreeSpinBonusPlayItem.create!(
            every_matrix_free_spin_bonus_id: free_spin_bonus.id,
            every_matrix_play_item_id: play_item_id
          )
        end
      end

      def create_free_spin_bonus_wallets!
        @free_spin_bonus_wallet_ids = []

        CSV.foreach(customers_csv.path, headers: true) do |row|
          customer_id = row['Id']
          wallet_type = row['Wallet'] == 'crypto' ? :crypto : :fiat
          wallet =
            Wallet.where(customer_id: customer_id).send(wallet_type).last

          next unless wallet

          free_spin_bonus_wallet = EveryMatrix::FreeSpinBonusWallet.create!(
            every_matrix_free_spin_bonus_id: free_spin_bonus.id,
            wallet: wallet
          )

          @free_spin_bonus_wallet_ids << free_spin_bonus_wallet.id
        end
      end

      def request_bonus_award
        free_spin_bonus_wallet_ids.each do |free_spin_bonus_wallet_id|
          AwardBonusWorker.perform_async(free_spin_bonus_wallet_id)
        end
      end
    end
  end
end
