# frozen_string_literal: true

describe CustomerBonuses::RolloverCalculationService do
  subject { service_object.call }

  let(:customer_bonus) do
    create(:customer_bonus, min_odds_per_bet: bonus_odds_theshold)
  end

  let(:odd) { create(:odd) }
  let(:service_object) { described_class.new(customer_bonus: customer_bonus) }

  context 'with settled bet' do
    let(:bet) do
      create(:bet,
             :won,
             odd: odd,
             amount: bet_amount,
             customer_bonus: customer_bonus)
    end

    context 'when Bet#amount < CustomerBonus#max_rollover_per_bet' do
      let(:bet_amount) { customer_bonus.max_rollover_per_bet / 2.0 }
      let(:bonus_odds_theshold) { odd.value - 0.1 }

      it 'substracts bet amount from rollover balance' do
        expect { subject }
          .to change(customer_bonus, :rollover_balance)
          .by(-bet.amount)
      end
    end

    context 'when Bet#amount > CustomerBonus#max_rollover_per_bet' do
      let(:bet_amount) { customer_bonus.max_rollover_per_bet * 2.0 }
      let(:bonus_odds_theshold) { odd.value - 0.1 }

      it 'substracts bet amount from rollover balance' do
        bet
        expect { subject }
          .to change(customer_bonus, :rollover_balance)
          .by(-customer_bonus.max_rollover_per_bet)
      end
    end

    context 'when Bet#odd_value < CustomerBonus#min_odds_per_bet' do
      let(:bet_amount) { customer_bonus.max_rollover_per_bet / 2.0 }
      let(:bonus_odds_theshold) { odd.value + 0.1 }

      it 'does not affect the rollover' do
        expect { subject }.not_to change(customer_bonus, :rollover_balance)
      end
    end
  end

  context 'with unsettled bet' do
    let(:bet) do
      create(:bet,
             odd: odd,
             amount: bet_amount,
             customer_bonus: customer_bonus)
    end
    let(:bet_amount) { customer_bonus.max_rollover_per_bet / 2.0 }
    let(:bonus_odds_theshold) { odd.value - 0.1 }

    it 'does not affect the rollover' do
      expect { subject }.not_to change(customer_bonus, :rollover_balance)
    end
  end

  context 'with completed customer bonus' do
    before { customer_bonus.complete! }

    let(:bet_amount) { customer_bonus.max_rollover_per_bet / 2.0 }
    let(:bonus_odds_theshold) { odd.value - 0.1 }

    it 'does not change the rollover' do
      expect { subject }.not_to change(customer_bonus, :rollover_balance)
    end
  end
end
