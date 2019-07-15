# frozen_string_literal: true

FactoryBot.define do
  factory :balance do
    kind   { Balance::REAL_MONEY }
    amount { Faker::Number.decimal(4, 2) }

    wallet

    trait :bonus do
      kind { Balance::BONUS }
    end

    trait :real_money do
      kind { Balance::REAL_MONEY }
    end
  end
end
