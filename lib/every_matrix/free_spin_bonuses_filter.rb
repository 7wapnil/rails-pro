# frozen_string_literal: true

module EveryMatrix
  class FreeSpinBonusesFilter
    def initialize(query_params: {}, page: nil)
      @query_params = query_params
      @page = page
    end

    def search
      EveryMatrix::FreeSpinBonus
        .includes(
          :vendor,
          :play_items,
          :free_spin_bonus_wallets,
          :initial_free_spin_bonus_wallets,
          :in_progress_free_spin_bonus_wallets,
          :awarded_free_spin_bonus_wallets,
          :forfeited_free_spin_bonus_wallets,
          :error_free_spin_bonus_wallets
        )
        .ransack(@query_params, search_key: :free_spin_bonuses)
    end

    def free_spin_bonuses
      FreeSpinBonusDecorator.decorate_collection(
        search.result.order(id: :desc).page(@page)
      )
    end
  end
end
