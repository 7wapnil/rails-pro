# frozen_string_literal: true

module EveryMatrix
  class FreeSpinBonusDecorator < ApplicationDecorator
    delegate :name, to: :vendor, allow_nil: true, prefix: true
    delegate :count, to: :play_items, prefix: true
    delegate :count, to: :free_spin_bonus_wallets, prefix: true
    delegate :count, to: :initial_free_spin_bonus_wallets, prefix: true
    delegate :count, to: :in_progress_free_spin_bonus_wallets, prefix: true
    delegate :count, to: :awarded_free_spin_bonus_wallets, prefix: true
    delegate :count, to: :forfeited_free_spin_bonus_wallets, prefix: true
    delegate :count, to: :error_free_spin_bonus_wallets, prefix: true
  end
end
