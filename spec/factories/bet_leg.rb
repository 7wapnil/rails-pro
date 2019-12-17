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

    BetLeg::SETTLEMENT_STATUSES.keys.each do |status|
      trait status do
        settlement_status { status.to_s }
      end
    end

    BetLeg::STATUSES.keys.each do |status|
      trait status do
        status { status.to_s }
      end
    end
  end
end
