# frozen_string_literal: true

FactoryBot.define do
  factory :entry_currency_rule do
    kind       { EntryRequest::DEPOSIT }
    min_amount { Faker::Number.decimal(1, 2) }
    max_amount { Faker::Number.decimal(4, 2) }

    currency

    initialize_with do
      EntryCurrencyRule
        .where(currency: currency, kind: kind)
        .first_or_initialize do |rule|
          rule.assign_attributes(
            min_amount: min_amount,
            max_amount: max_amount
          )
        end
    end
  end
end
