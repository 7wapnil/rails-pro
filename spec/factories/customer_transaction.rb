# frozen_string_literal: true

FactoryBot.define do
  factory :customer_transaction do
    transient do
      customer { create :customer }
    end

    trait :with_entry_request do
      association :entry_request, strategy: :build
    end

    trait :with_customer do
      after(:create) do |instance, options|
        create :entry_request,
               (instance.type == 'Deposit' ? :deposit : :withdrawal),
               origin:     instance,
               customer:   options.customer,
               status:     EntryRequest::SUCCEEDED,
               mode:       EntryRequest::BITCOIN,
               created_at: Faker::Time.backward(5)
      end
    end
  end
end
