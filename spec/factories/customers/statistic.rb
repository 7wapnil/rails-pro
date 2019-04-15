# frozen_string_literal: true

FactoryBot.define do
  factory :customer_statistic, class: Customers::Statistic.name do
    deposit_count          { rand(5..15) }
    deposit_value          { rand(50..1000.0).round(2) }
    withdrawal_count       { rand(5..15) }
    withdrawal_value       { rand(50..1000.0).round(2) }
    theoretical_bonus_cost { rand(50..1000.0).round(2) }
    potential_bonus_cost   { rand(50..1000.0).round(2) }
    actual_bonus_cost      { rand(50..1000.0).round(2) }
    prematch_bet_count     { rand(5..15) }
    prematch_wager         { rand(50..1000.0).round(2) }
    prematch_payout        { rand(50..1000.0).round(2) }
    live_bet_count         { rand(5..15) }
    live_sports_wager      { rand(50..1000.0).round(2) }
    live_sports_payout     { rand(50..1000.0).round(2) }
    total_pending_bet_sum  { rand(50..1000.0).round(2) }
    updated_at             { rand(5).days.ago }

    association :customer, strategy: :build
  end
end
