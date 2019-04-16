# frozen_string_literal: true

FactoryBot.define do
  factory :currency do
    name          { Faker::Currency.name }
    code          { Currency.available_currency_codes.sample }
    primary       { false }
    kind          { Currency::FIAT }
    exchange_rate { nil }

    trait :primary do
      primary { true }
    end

    trait :with_bet_rule do
      after(:create) do |currency|
        bet_kind = EntryRequest::BET
        create(:entry_currency_rule, currency: currency, kind: bet_kind)
      end
    end

    trait :with_refund_rule do
      after(:create) do |currency|
        kind = EntryRequest::REFUND
        create(:entry_currency_rule, currency: currency, kind: kind)
      end
    end

    trait :with_withdrawal_rule do
      after(:create) do |currency|
        withdraw_kind = EntryRequest::WITHDRAW
        create(:entry_currency_rule,
               currency: currency,
               kind: withdraw_kind,
               min_amount: -1000,
               max_amount: 0)
      end
    end

    trait :allowed_by_safe_charge do
      code do
        (Currency.available_currency_codes &
          SafeCharge::Currency::AVAILABLE_CURRENCY_LIST).sample
      end
    end
  end
end
