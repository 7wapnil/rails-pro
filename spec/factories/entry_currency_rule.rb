# frozen_string_literal: true

FactoryBot.define do
  factory :entry_currency_rule do
    kind       { EntryRequest::DEPOSIT }
    min_amount { Faker::Number.decimal(1, 2) }
    max_amount { Faker::Number.decimal(4, 2) }

    currency

    initialize_with do
      EntryCurrencyRule
        .find_or_initialize_by(currency: currency, kind: kind) do |rule|
          rule.assign_attributes(
            min_amount: min_amount,
            max_amount: max_amount
          )
        end
    end

    EntryKinds::KINDS.keys.each do |kind|
      trait(kind.to_sym) do
        kind { kind }
      end
    end
  end
end
