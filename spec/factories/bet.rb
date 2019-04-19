# frozen_string_literal: true

FactoryBot.define do
  factory :bet do
    amount    { Faker::Number.decimal(2, 2) }
    odd_value { odd.value }
    status    { StateMachines::BetStateMachine::INITIAL }

    association :odd, factory: %i[odd active]
    currency
    association :customer, :ready_to_bet

    trait :sent_to_external_validation do
      status { StateMachines::BetStateMachine::SENT_TO_EXTERNAL_VALIDATION }

      after(:create) do |bet|
        bet_kind = EntryRequest::BET
        wallet = bet.customer.wallets.take
        create(:entry, kind: bet_kind, origin: bet, wallet: wallet)
      end
    end

    trait :won do
      settlement_status { :won }
    end

    trait :lost do
      settlement_status { :lost }
    end

    trait :void do
      settlement_status { nil }
      void_factor { 1.0 }
    end

    trait :with_random_market do
      after :build do |instance|
        instance.market = FactoryBot.random_or_create :market
      end
    end

    StateMachines::BetStateMachine::BET_SETTLEMENT_STATUSES.keys.each do |state|
      trait state do
        settlement_status { state.to_s }
      end
    end

    StateMachines::BetStateMachine::BET_STATUSES.keys.each do |status|
      trait status do
        status { status.to_s }
      end
    end
  end
end
