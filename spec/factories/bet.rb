# frozen_string_literal: true

FactoryBot.define do
  factory :bet do
    amount { Faker::Number.decimal(2, 2) }
    base_currency_amount { amount * Faker::Number.decimal(2, 2).to_f }
    status { StateMachines::BetStateMachine::INITIAL }

    currency
    association :customer, :ready_to_bet

    transient do
      odd { nil }
      winning { nil }
    end

    after(:create) do |bet, evaluator|
      next if evaluator.odd.nil?

      create(:bet_leg, bet: bet,
                       odd: evaluator.odd,
                       odd_value: evaluator.odd.value)
    end

    after(:create) do |bet, evaluator|
      next unless evaluator.winning.is_a?(Entry)

      evaluator.winning.update(origin: bet)
    end

    trait :with_settled_bet_leg do
      after(:create) do |bet, evaluator|
        odd = evaluator.odd || create(:odd)

        create(:bet_leg, bet: bet,
                         odd: odd,
                         odd_value: odd.value,
                         settlement_status: bet.settlement_status ||
                                            BetLeg::VOIDED)
      end
    end

    trait :with_placement_entry do
      after(:create) do |bet|
        wallet = bet.customer.wallets.take
        bet.update(currency: wallet.currency)
        balance_trait = if bet.customer_bonus.present?
                          :with_real_money_balance_entry
                        else
                          :with_balance_entries
                        end

        create(:entry, :bet, balance_trait, origin: bet,
                                            wallet: wallet,
                                            amount: -bet.amount)
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
      status { StateMachines::BetStateMachine::SETTLED }
      settlement_status { Bet::WON }

      after(:create) do |bet, evaluator|
        next if evaluator.winning

        wallet = bet.customer.wallet || create(:wallet)
        bet.update(currency: wallet.currency)
        create(:entry, :win, origin: bet, wallet: wallet)
      end
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

    trait :with_bet_leg do
      after(:create) do |bet|
        create(:bet_leg, bet: bet)
      end
    end

    trait :combo_bets do
      combo_bets { true }
    end

    trait :with_random_market do
      after(:create) do |bet|
        create(:bet_leg, :with_random_market, bet: bet)
      end
    end

    trait :with_bonus do
      transient do
        bonus_status { CustomerBonus::ACTIVE }
      end

      after(:create) do |bet, evaluator|
        wallet = bet.customer.wallets.find_by(currency: bet.currency)
        wallet ||= bet.customer.wallets.take
        bonus = create(:customer_bonus, customer: bet.customer,
                                        wallet: wallet,
                                        status: evaluator.bonus_status)

        bet.update(customer_bonus: bonus)
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
