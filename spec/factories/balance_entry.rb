# frozen_string_literal: true

FactoryBot.define do
  factory :balance_entry do
    amount { Faker::Number.decimal(3, 2) }

    entry
    association :balance, strategy: :build

    trait :bonus do
      association :balance, factory: %i[balance bonus], strategy: :build
    end
  end
end
