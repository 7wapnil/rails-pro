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
        last_four_digits = Faker::Number.number(4)

        {
          holder_name: Faker::WorldOfWarcraft.hero,
          masked_account_number: "5 **** #{last_four_digits}",
          token_id: SecureRandom.hex(7)
        }
      end
    end

    trait :bitcoin do
      details { { address: "tb1#{SecureRandom.hex(30)}" } }
    end

    trait :skrill do
      details do
        {
          name: SecureRandom.hex(7),
          user_payment_option_id: SecureRandom.hex(7)
        }
      end
    end

    trait :neteller do
      details do
        {
          name: SecureRandom.hex(7),
          user_payment_option_id: SecureRandom.hex(7)
        }
      end
    end

    trait :idebit do
      details do
        {
          name: SecureRandom.hex(7),
          user_payment_option_id: SecureRandom.hex(7)
        }
      end
    end
  end
end
