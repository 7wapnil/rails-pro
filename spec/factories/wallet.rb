# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    amount { Faker::Number.decimal(5, 2) }

    customer
    currency

    trait :brick do
      amount { 100_000 }
    end

    trait :crypto do
      association :currency, :crypto
    end
  end
end
