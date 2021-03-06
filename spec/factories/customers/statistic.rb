# frozen_string_literal: true

FactoryBot.define do
  factory :customer_statistic, class: Customers::Statistic.name do
    deposit_count         { rand(5..15) }
    deposit_value         { rand(50..1000.0).round(2) }
    withdrawal_count      { rand(5..15) }
    withdrawal_value      { rand(50..1000.0).round(2) }
    total_bonus_awarded   { rand(50..1000.0).round(2) }
    total_bonus_completed { rand(50..1000.0).round(2) }
    prematch_bet_count    { rand(5..15) }
    prematch_wager        { rand(50..1000.0).round(2) }
    prematch_payout       { rand(50..1000.0).round(2) }
    live_bet_count        { rand(5..15) }
    live_sports_wager     { rand(50..1000.0).round(2) }
    live_sports_payout    { rand(50..1000.0).round(2) }
    casino_game_count     { rand(5..15) }
    casino_game_wager     { rand(50..1000.0).round(2) }
    casino_game_payout    { rand(50..1000.0).round(2) }
    live_casino_count     { rand(5..15) }
    live_casino_wager     { rand(50..1000.0).round(2) }
    live_casino_payout    { rand(50..1000.0).round(2) }
    total_pending_bet_sum { rand(50..1000.0).round(2) }
    updated_at            { rand(5).days.ago }
    last_updated_at       { rand(7).days.ago }

    association :customer, strategy: :build

    trait :empty do
      deposit_count         { 0.0 }
      deposit_value         { 0.0 }
      withdrawal_count      { 0.0 }
      withdrawal_value      { 0.0 }
      total_bonus_awarded   { 0.0 }
      total_bonus_completed { 0.0 }
      prematch_bet_count    { 0.0 }
      prematch_wager        { 0.0 }
      prematch_payout       { 0.0 }
      live_bet_count        { 0.0 }
      live_sports_wager     { 0.0 }
      live_sports_payout    { 0.0 }
      total_pending_bet_sum { 0.0 }
      casino_game_count     { 0.0 }
      casino_game_wager     { 0.0 }
      casino_game_payout    { 0.0 }
      live_casino_count     { 0.0 }
      live_casino_wager     { 0.0 }
      live_casino_payout    { 0.0 }
      updated_at            {}
      last_updated_at       {}
    end
  end
end
