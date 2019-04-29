# frozen_string_literal: true

FactoryBot.define do
  factory :bonus do
    kind                 { Bonus::DEPOSIT }
    rollover_multiplier  { 10 }
    max_rollover_per_bet { 150.00 }
    max_deposit_match    { 1000.00 }
    min_odds_per_bet     { 1.6 }
    min_deposit          { 10.00 }
    expires_at           { Time.zone.now.end_of_month }
    valid_for_days       { 60 }
    percentage           { 100 }
    repeatable           { true }

    sequence(:code)      { |n| "FOOBAR#{n}" }
  end
end
