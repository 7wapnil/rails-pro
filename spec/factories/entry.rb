# frozen_string_literal: true

FactoryBot.define do
  factory :entry do
    kind          { Entry::DEPOSIT }
    amount        { Faker::Number.decimal(3, 2) }
    authorized_at { nil }

    wallet

    before(:create) do |entry|
      create(:entry_currency_rule,
             currency: entry.currency,
             kind: entry.kind)
    end
  end
end
