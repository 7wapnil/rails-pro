# frozen_string_literal: true

FactoryBot.define do
  factory :bet do
    amount    { Faker::Number.decimal(2, 2) }
    odd_value { odd.value }
    status    { StateMachines::BetStateMachine::INITIAL }
    message   { Faker::Games::WorldOfWarcraft.quote }

    association :odd, factory: %i[odd active], strategy: :random_or_create
    association :currency, strategy: :random_or_create
    association :customer, :ready_to_bet, strategy: :random_or_create
    association :market, strategy: :random_or_create

    trait :settled do
      status { StateMachines::BetStateMachine::SETTLED }
    end

    trait :accepted do
      status { StateMachines::BetStateMachine::ACCEPTED }
    end

    trait :sent_to_internal_validation do
      status { StateMachines::BetStateMachine::SENT_TO_INTERNAL_VALIDATION }
    end

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
  end
end
