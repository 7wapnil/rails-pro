# frozen_string_literal: true

describe BalanceCalculations::Bet do
  subject(:service_call_response) { described_class.call(bet: bet) }

  let(:amount) { rand(10..100).to_f }
  let(:customer_bonus) { create(:customer_bonus, rollover_balance: rand(100)) }
  let(:bet) { create(:bet, amount: amount, customer_bonus: customer_bonus) }
  let!(:wallet) do
    create(
      :wallet,
      amount: full_balance,
      real_money_balance: real_money_balance,
      bonus_balance: bonus_balance,
      currency: bet.currency,
      customer: bet.customer
    )
  end

  let(:full_balance) { rand(100..500).to_f }
  let(:ratio) { 0.75 }
  let(:real_money_balance) { full_balance * ratio }
  let(:bonus_balance) { full_balance * (1 - ratio) }

  let(:real_money_winning) { -(amount * ratio).round(2) }
  let(:bonus_winning) { -(amount * (1 - ratio)).round(2) }

  context 'with existent bonus balance and real money balance' do
    it 'calculates real and bonus amount' do
      expect(service_call_response)
        .to eq(real_money_amount: real_money_winning,
               bonus_amount: bonus_winning)
    end
  end

  context 'with inactive customer bonus' do
    let(:customer_bonus) { nil }

    it 'calculates real amount' do
      expect(service_call_response)
        .to eq(real_money_amount: -amount, bonus_amount: 0)
    end
  end

  context 'without real money on balance' do
    let!(:real_money_balance) { 0 }

    it 'calculates bonus amount' do
      expect(service_call_response)
        .to eq(real_money_amount: 0, bonus_amount: -amount)
    end
  end

  context 'without balance money' do
    let!(:bonus_balance) { 0 }

    it 'calculates real amount' do
      expect(service_call_response)
        .to eq(real_money_amount: -amount, bonus_amount: 0)
    end
  end
end
