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
    deleted_at           { nil }
    expiration_reason    { nil }
    rollover_balance     { rand(100..1000) }
    rollover_initial_value { rand(100..1000) }

    sequence(:code) { |n| "FOOBAR#{n}" }

    customer
    wallet
    association :original_bonus, factory: :bonus

    trait :applied do
      deleted_at {}
      valid_for_days { rand(1..20) }
      rollover_balance { Faker::Number.decimal(2, 2).to_f }
      rollover_initial_value { rollover_balance }
    end

    trait :activated do
      entry { create(:entry) }
    end

    trait :expired do
      created_at { (valid_for_days + 1).days.ago }
    end
  end
end
