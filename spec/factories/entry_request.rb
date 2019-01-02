# frozen_string_literal: true

FactoryBot.define do
  factory :entry_request do
    status  { EntryRequest::PENDING }
    mode    { EntryRequest::CASHIER }
    kind    { EntryRequest.kinds.keys.first }
    amount  { Random.new.rand(1.00..200.00).round(2) }
    comment { Faker::Lorem.paragraph }

    customer
    currency
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
          amount: entry_request.amount
        )
      end
    end

    trait :succeeded do
      status { EntryRequest::SUCCEEDED }
    end
  end
end
