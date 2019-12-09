# frozen_string_literal: true

FactoryBot.define do
  factory :bet_leg do
    odd_value { odd.value }

    association :bet
    association :odd, factory: %i[odd active]

    trait :with_random_market do
      after :build do |instance|
        instance.market = FactoryBot.random_or_create :market
      end
    end

    trait :won do
      settlement_status { BetLeg::WON }
    end
  end
end
