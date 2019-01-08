# frozen_string_literal: true

FactoryBot.define do
  factory :entry do
    kind          { EntryRequest.kinds.keys.first }
    amount        { Faker::Number.decimal(3, 2) }
    authorized_at { nil }

    wallet
  end
end
