# frozen_string_literal: true

FactoryBot.define do
  factory :every_matrix_transaction, class: EveryMatrix::Transaction.name do
    amount { rand(1..1_000) }
    transaction_id { rand(1e9) }
    play_item { create(:casino_game) }
    customer
    wallet_session
    entry
    game_round

    trait :random do
      type { [EveryMatrix::Wager, EveryMatrix::Result].sample.name }
    end

    trait :wager do
      type { EveryMatrix::Wager.name }
    end

    trait :result do
      type { EveryMatrix::Result.name }
    end

    trait :rollback do
      type { EveryMatrix::Rollback.name }
    end

    trait :live_casino do
      play_item { create(:casino_table) }
    end
  end
end
