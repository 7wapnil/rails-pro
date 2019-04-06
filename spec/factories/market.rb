# frozen_string_literal: true

FactoryBot.define do
  factory :market do
    visible         { true }
    name            { 'Winner Map (Train)' }
    priority        { 2 }
    status          { StateMachines::MarketStateMachine::ACTIVE }
    previous_status { StateMachines::MarketStateMachine::ACTIVE }

    sequence :external_id do |n|
      "sr:match:#{n}:#{rand(0..10_000)}/setnr=2|gamenrX=#{n}|gamenrY=#{n}"
    end

    event

    trait :with_odds do
      after(:create) do |market|
        create_list :odd, 2, :active, market: market
      end
    end

    trait :with_inactive_odds do
      after(:create) do |market|
        create_list :odd, 2, market: market
      end
    end

    trait :suspended do
      status { Market::SUSPENDED }
    end

    trait :settled do
      status { StateMachines::MarketStateMachine::SETTLED }
    end
  end
end
