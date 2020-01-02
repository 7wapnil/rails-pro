# frozen_string_literal: true

FactoryBot.define do
  factory :free_spin_bonus_wallet,
          class: EveryMatrix::FreeSpinBonusWallet.name do
    wallet
    free_spin_bonus
    status { 'initial' }
  end
end
