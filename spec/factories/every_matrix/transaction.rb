# frozen_string_literal: true

FactoryBot.define do
  factory :every_matrix_transaction, class: EveryMatrix::Transaction.name do
    amount { rand(1_000) }
    transaction_id { rand(1e9) }
    customer
    wallet_session
    entry

    trait :wager do
      type { 'EveryMatrix::Wager' }
    end

    trait :result do
      type { 'EveryMatrix::Result' }
    end

    trait :rollback do
      type { 'EveryMatrix::Rollback' }
    end
  end
end
