# frozen_string_literal: true

FactoryBot.define do
  factory :currency do
    name    { Faker::Currency.name }
    code    { Currency.available_currency_codes.sample }
    primary { false }

    trait :primary do
      primary { true }
    end

    trait :with_bet_rule do
      after(:create) do |currency|
        bet_kind = EntryRequest::BET
        create(:entry_currency_rule, currency: currency, kind: bet_kind)
      end
    end
  end
end
