# frozen_string_literal: true

describe CustomerBonuses::RollbackBonusRolloverService do
  subject { described_class.call(bet: bet) }

  let(:bet) do
    create(:bet, :rejected, customer: customer,
                            amount: bet_amount,
                            odd: create(:odd, value: odd_value),
                            customer_bonus: customer_bonus,
                            counted_towards_rollover: counted_towards_rollover)
  end
  let(:odd_value) { 2.5 }
  let(:counted_towards_rollover) { true }
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

    context 'bet has not been counted towards rollover' do
      let(:odd_value) { customer_bonus.min_odds_per_bet - 1 }
      let(:counted_towards_rollover) { false }

      it 'does not revert rollover balance' do
        subject

        expect(customer_bonus.rollover_balance).to eq(initial_rollover)
      end
    end
  end
end
