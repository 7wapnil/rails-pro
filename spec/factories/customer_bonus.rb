# frozen_string_literal: true

FactoryBot.define do
  factory :customer_bonus do
    kind                 { Bonus::DEPOSIT }
    rollover_multiplier  { 10 }
    max_rollover_per_bet { 150.00 }
    max_deposit_match    { 1000.00 }
    min_odds_per_bet     { 1.6 }
    min_deposit          { 10.00 }
    expires_at           { Time.zone.now.end_of_month }
    valid_for_days       { 60 }
    created_at           { Time.zone.now }
    rollover_balance     { rand(100..1000) }
    rollover_initial_value { rollover_balance }
    status                 { CustomerBonus::ACTIVE }
    activated_at           { Time.zone.now + 1.minute }

    sequence(:code) { |n| "FOOBAR#{n}" }

    customer
    wallet
    association :original_bonus, factory: :bonus, strategy: :build

    trait :initial do
      status { CustomerBonus::INITIAL }
    end

    trait :expired do
      activated_at { (valid_for_days + 1).days.ago }
    end

    trait :with_balance_entry do
      association :balance_entry, factory: %i[balance_entry bonus],
                                  strategy: :build
    end

    trait :with_empty_bonus_balance do
      after :create do |customer_bonus|
        create(:balance, :bonus, wallet: customer_bonus.wallet, amount: 0)
      end
    end

    trait :with_positive_bonus_balance do
      after :create do |customer_bonus|
        create(:balance, :bonus, wallet: customer_bonus.wallet, amount: 10)
      end
    end
  end
end
