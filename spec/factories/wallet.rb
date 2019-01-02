# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    amount { Faker::Number.decimal(3, 2) }

    customer
    currency

    trait :brick do
      amount { 100_000 }
    end
  end
end
