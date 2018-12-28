# frozen_string_literal: true

FactoryBot.define do
  factory :entry_currency_rule do
    kind       { EntryRequest.kinds.keys.first }
    min_amount { Faker::Number.decimal(1, 2) }
    max_amount { Faker::Number.decimal(4, 2) }

    currency
  end
end
