# frozen_string_literal: true

FactoryBot.define do
  factory :currency do
    code          { Currency::FIAT_CODES.sample }
    name          { "#{code} currency name" }
    primary       { false }
    kind          { Currency::FIAT }
    exchange_rate { 1 }

    initialize_with do
      Currency.find_by(code: code) ||
        Currency.find_by(name: name) ||
        Currency.create!(attributes)
    end

    trait :with_low_exchange_rate do
      code { (Currency::FIAT_CODES - [Currency::PRIMARY_CODE]).sample }
      exchange_rate { rand(1.0...2.0) }
    end

    trait :primary do
      code { ::Currency::PRIMARY_CODE }
      primary { true }
    end

    trait :non_primary do
      code { Currency::FIAT_CODES.without(Currency::PRIMARY_CODE).sample }
    end

    trait :crypto do
      code { Faker::CryptoCoin.acronym }
      kind { Currency::CRYPTO }
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
        allowed_currencies =
          Currency::FIAT_CODES &
          ::Payments::Fiat::SafeCharge::Currency::AVAILABLE_CURRENCY_LIST[
            ::Payments::Fiat::SafeCharge::Methods::CC_CARD
          ]

        allowed_currencies.sample
      end
    end
  end
end
