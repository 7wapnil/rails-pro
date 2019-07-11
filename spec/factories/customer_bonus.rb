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

    trait :expired do
      activated_at { (valid_for_days + 1).days.ago }
    end

    trait :with_balance_entry do
      association :balance_entry, factory: %i[balance_entry bonus],
                                  strategy: :build
    end

    CustomerBonus.statuses.keys.each do |status|
      trait(status.to_sym) do
        status { status }
      end
    end
  end
end
