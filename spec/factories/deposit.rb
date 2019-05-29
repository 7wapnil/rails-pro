# frozen_string_literal: true

FactoryBot.define do
  factory :deposit do
    trait :with_bonus do
      association :customer_bonus, factory: :customer_bonus,
                                   strategy: :build
    end

    trait :with_entry_request do
      association :entry_request, strategy: :build
    end
  end
end
