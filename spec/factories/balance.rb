# frozen_string_literal: true

FactoryBot.define do
  factory :balance do
    kind   { Balance::REAL_MONEY }
    amount { Faker::Number.decimal(3, 2) }

    wallet
  end
end
