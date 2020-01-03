# frozen_string_literal: true

FactoryBot.define do
  factory :wallet_session, class: EveryMatrix::WalletSession.name do
    wallet

    play_item { create(:casino_game) }

    trait :live_casino do
      play_item { create(:casino_table) }
    end
  end
end
