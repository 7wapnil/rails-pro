# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    amount { Faker::Number.decimal(5, 2) }
    real_money_balance { Faker::Number.decimal(4, 2) }
    bonus_balance { Faker::Number.decimal(4, 2) }

    customer
    currency

    initialize_with do
      Wallet.find_or_initialize_by(customer: customer, currency: currency)
    end

    trait :brick do
      amount { 100_000 }
    end

    trait :fiat do
      association :currency
    end

    trait :non_primary_fiat do
      association :currency, :non_primary
    end

    trait :crypto do
      association :currency, :crypto
    end

    trait :crypto_btc do
      association :currency, :crypto, code: Currencies::Crypto::M_BTC
    end

    trait :with_crypto_address do
      after(:create) { |wallet| create(:crypto_address, wallet: wallet) }
    end

    trait :empty do
      amount { 0 }
      real_money_balance { 0 }
      bonus_balance { 0 }
    end
  end
end
