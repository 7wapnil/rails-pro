# frozen_string_literal: true

FactoryBot.define do
  factory :deposit, parent: :customer_transaction do
    type   { Deposit }
    status { Deposit::PENDING }

    trait :with_bonus do
      association :customer_bonus, factory: :customer_bonus,
                                   strategy: :build
    end
  end
end
