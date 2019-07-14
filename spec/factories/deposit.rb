# frozen_string_literal: true

FactoryBot.define do
  factory :deposit, class: 'Deposit', parent: :customer_transaction do
    type   { Deposit }
    status { Deposit::PENDING }

    trait :with_bonus do
      association :customer_bonus, factory: :customer_bonus,
                                   strategy: :build
    end

    trait :credit_card do
      details do
        {
          holder_name: Faker::WorldOfWarcraft.hero,
          last_four_digits: Faker::Number.number(4)
        }
      end
    end

    trait :bitcoin do
      details { { address: "tb1#{SecureRandom.hex(30)}" } }
    end

    trait :skrill do
      details { { email: Faker::Internet.email } }
    end

    trait :neteller do
      details do
        {
          account_id: SecureRandom.hex(7),
          secure_id: SecureRandom.hex(7)
        }
      end
    end
  end
end
