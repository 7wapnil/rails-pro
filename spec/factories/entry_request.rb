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

    trait :succeeded do
      status { EntryRequest::SUCCEEDED }
      sequence(:external_id) { |n| "ID_#{n}" }
    end

    trait :with_entry do
      after(:build) do |entry_request|
        create(
          :entry_currency_rule,
          currency:   entry_request.currency,
          kind:       entry_request.kind,
          min_amount: -entry_request.amount.abs,
          max_amount: entry_request.amount.abs
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
          external_id: entry_request.external_id,
          entry_request: entry_request,
          origin: entry_request.origin
        )
      end
    end

    EntryRequest.statuses.keys.each do |status|
      trait(status.to_sym) do
        status { status }
      end
    end

    EntryKinds::KINDS.keys.each do |kind|
      trait(kind.to_sym) do
        kind { kind }
      end
    end

    trait :win do
      kind { EntryKinds::WIN }
    end

    trait :system do
      mode { EntryRequest::INTERNAL }
    end
  end
end
