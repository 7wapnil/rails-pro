# frozen_string_literal: true

FactoryBot.define do
  factory :balance_entry do
    amount { Faker::Number.decimal(3, 2) }

    entry
    balance
  end
end
