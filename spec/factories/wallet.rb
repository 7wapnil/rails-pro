# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    amount { Faker::Number.decimal(5, 2) }

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

    trait :crypto do
      association :currency, :crypto
    end
  end
end
