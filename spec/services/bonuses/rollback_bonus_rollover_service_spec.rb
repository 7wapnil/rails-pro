# frozen_string_literal: true

describe Bonuses::RollbackBonusRolloverService do
  subject { described_class.call(bet: bet) }

  let(:bet) do
    create(:bet, :rejected, customer: customer,
                            amount: bet_amount,
                            odd: create(:odd, value: odd_value),
                            customer_bonus: customer_bonus)
  end
  let(:odd_value) { 2.5 }
  let(:customer_bonus) do
    create(:customer_bonus,
           customer: customer,
           wallet: customer.wallets.first,
           rollover_balance: initial_rollover,
           rollover_initial_value: initial_rollover)
  end
  let(:initial_rollover) { 1000 }
  let(:customer) { create(:customer, :ready_to_bet) }
  let(:bet_amount) { rand(10..100) }

  describe 'call' do
    context 'bet amount < max rollover per bet' do
      let(:bet_amount) { customer_bonus.max_rollover_per_bet - 10 }

      it 'reverts rollover balance' do
        subject

        expect(customer_bonus.rollover_balance)
          .to eq(initial_rollover + bet.amount)
      end
    end

    context 'bet amount > max rollover per bet' do
      let(:bet_amount) { customer_bonus.max_rollover_per_bet + 10 }

      it 'reverts rollover balance' do
        subject

        expect(customer_bonus.rollover_balance)
          .to eq(initial_rollover + customer_bonus.max_rollover_per_bet)
      end
    end

    context 'bet ood value < customer bonus min odds per bet' do
      let(:odd_value) { customer_bonus.min_odds_per_bet - 1 }

      it 'does not revert rollover balance' do
        subject

        expect(customer_bonus.rollover_balance).to eq(initial_rollover)
      end
    end
  end
end
