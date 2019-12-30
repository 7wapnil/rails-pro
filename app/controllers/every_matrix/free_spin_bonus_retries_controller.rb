# frozen_string_literal: true

module EveryMatrix
  class FreeSpinBonusRetriesController < ApplicationController
    find :free_spin_bonus,
         only: %i[update],
         class: EveryMatrix::FreeSpinBonus,
         eager_load: {
           free_spin_bonus_wallets: {
             wallet: %i[customer currency]
           },
           free_spin_bonus_play_items: :play_item
         }

    def update
      free_spin_bonus_wallet_ids =
        @free_spin_bonus.error_free_spin_bonus_wallets.pluck(:id)

      free_spin_bonus_wallet_ids.each do |free_spin_bonus_wallet_id|
        FreeSpinBonuses::RetryWorker.perform_async(free_spin_bonus_wallet_id)
      end

      redirect_to(
        every_matrix_free_spin_bonuses_path,
        flash: {
          notice: t('bonus_retry_requested',
                    number: free_spin_bonus_wallet_ids.count)
        }
      )
    end
  end
end
