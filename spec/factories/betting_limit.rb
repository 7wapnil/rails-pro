# frozen_string_literal: true

FactoryBot.define do
  factory :betting_limit do
    live_bet_delay    { Faker::Number.between(1, 10) }
    user_max_bet      { Faker::Number.between(1, 1000) }
    max_loss          { Faker::Number.between(1, 1000) }
    max_win           { Faker::Number.between(1, 1000) }
    user_stake_factor { Faker::Number.decimal(1, 1) }
    live_stake_factor { Faker::Number.decimal(1, 1) }

    customer
    title
  end
end
