# frozen_string_literal: true

FactoryBot.define do
  factory :deposit_limit do
    value { Faker::Number.decimal(3, 1) }
    range { 30 }

    customer
    currency

    trait :reached do
      after(:create) do |deposit_limit|
        create(
          :entry_request,
          :with_entry,
          customer: deposit_limit.customer,
          currency: deposit_limit.currency,
          kind:     :deposit,
          amount:   deposit_limit.value
        )
      end
    end
  end
end
