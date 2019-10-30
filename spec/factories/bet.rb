# frozen_string_literal: true

FactoryBot.define do
  factory :bet do
    amount { Faker::Number.decimal(2, 2) }
    base_currency_amount { amount * Faker::Number.decimal(2, 2).to_f }
    odd_value { odd.value }
    status    { StateMachines::BetStateMachine::INITIAL }

    currency
    association :odd, factory: %i[odd active]
    association :customer, :ready_to_bet

    trait :with_placement_entry do
      after(:create) do |bet|
        wallet = bet.customer.wallets.take
        bet.update(currency: wallet.currency)
        create(:entry, :bet, :with_real_money_balance_entry,
               origin: bet,
               wallet: wallet)
      end
    end

    trait :manually_settled do
      status { StateMachines::BetStateMachine::MANUALLY_SETTLED }
      bet_settlement_status_achieved_at { 1.day.ago.midday }
      settlement_status { Bet::LOST }
    end

    trait :recently_settled do
      status { StateMachines::BetStateMachine::SETTLED }
      bet_settlement_status_achieved_at { 1.day.ago.midday }
      settlement_status { Bet::LOST }
    end

    trait :sent_to_external_validation do
      status { StateMachines::BetStateMachine::SENT_TO_EXTERNAL_VALIDATION }
    end

    trait :won do
      status            { StateMachines::BetStateMachine::SETTLED }
      settlement_status { Bet::WON }
      association :winning, factory: %i[entry win]
    end

    trait :lost do
      status            { StateMachines::BetStateMachine::SETTLED }
      settlement_status { Bet::LOST }
    end

    trait :void do
      void_factor { 1.0 }
      settlement_status { Bet::VOIDED }
    end

    trait :with_notification do
      notification_code { Bets::Notification::EXCEPTION_CODES.sample }
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
