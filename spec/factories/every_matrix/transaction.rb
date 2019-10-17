# frozen_string_literal: true

FactoryBot.define do
  factory :every_matrix_transaction, class: EveryMatrix::Transaction.name do
    type { 'EveryMatrix::Wager' }
    transaction_id { rand(1e9) }
    customer
    em_wallet_session
  end
end
