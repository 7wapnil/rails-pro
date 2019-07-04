# frozen_string_literal: true

FactoryBot.define do
  factory :customers_summary, class: Customers::Summary.name do
    day { Date.today }
    bonus_wager_amount { rand(0.0..10_000.00).round(2) }
    real_money_wager_amount { rand(0.0..10_000.00).round(2) }
    bonus_payout_amount { rand(0.0..10_000.00).round(2) }
    real_money_payout_amount { rand(0.0..10_000.00).round(2) }
    bonus_deposit_amount { rand(0.0..10_000.00).round(2) }
    real_money_deposit_amount { rand(0.0..10_000.00).round(2) }
    withdraw_amount { rand(0.0..10_000.00).round(2) }
    signups_count { rand(0..1_000) }
    betting_customer_ids { (0..rand(100)).map { rand(1_000) } }
  end
end
