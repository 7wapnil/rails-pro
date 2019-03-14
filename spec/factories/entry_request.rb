# frozen_string_literal: true

FactoryBot.define do
  factory :entry_request do
    status  { EntryRequest::INITIAL }
    mode    { EntryRequest::CASHIER }
    kind    { EntryRequest::DEPOSIT }
    amount  { Random.new.rand(1.00..200.00).round(2) }
    comment { Faker::Lorem.paragraph }
    created_at { Faker::Time.backward(5) }

    customer
    association :currency, factory: %i[currency allowed_by_safe_charge],
                           strategy: :build
    association :initiator, factory: :customer

    trait :with_entry do
      after(:create) do |entry_request|
        create(
          :entry_currency_rule,
          currency:   entry_request.currency,
          kind:       entry_request.kind,
          min_amount: 0,
          max_amount: entry_request.amount
        )
        wallet = create(
          :wallet,
          customer: entry_request.customer,
          currency: entry_request.currency
        )
        create(
          :entry,
          wallet: wallet,
          kind:   entry_request.kind,
          amount: entry_request.amount,
          external_id: entry_request.external_id
        )
      end
    end

    trait :succeeded do
      status { EntryRequest::SUCCEEDED }
      sequence(:external_id) { |n| "ID_#{n}" }
    end

    trait :deposit do
      kind { EntryRequest::DEPOSIT }
    end

    trait :withdraw do
      kind { EntryRequest::WITHDRAW }
    end

    trait :refund do
      kind { EntryRequest::REFUND }
    end
  end
end
