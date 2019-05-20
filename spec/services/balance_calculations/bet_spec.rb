# frozen_string_literal: true

describe BalanceCalculations::Bet do
  subject(:service_call_response) { described_class.call(bet: bet) }

  let(:amount) { rand(10..100).to_f }
  let(:customer_bonus) { create(:customer_bonus, rollover_balance: rand(100)) }
  let(:bet) { create(:bet, amount: amount, customer_bonus: customer_bonus) }
  let(:wallet) do
    create(:wallet, currency: bet.currency, customer: bet.customer)
  end

  let(:full_balance) { rand(100..500).to_f }
  let(:ratio) { 0.75 }
  let!(:real_money_balance) do
    create(:balance, :real_money, amount: full_balance * ratio, wallet: wallet)
  end
  let!(:bonus_balance) do
    create(:balance, :bonus, amount: full_balance * (1 - ratio), wallet: wallet)
  end

  let(:real_money_winning) { -(amount * ratio).round(2) }
  let(:bonus_winning) { -(amount * (1 - ratio)).round(2) }

  context 'with existent bonus balance and real money balance' do
    it 'calculates real and bonus amount' do
      expect(service_call_response)
        .to eq(real_money: real_money_winning, bonus: bonus_winning)
    end
  end

  context 'with inactive customer bonus' do
    let(:customer_bonus) { nil }

    it 'calculates real amount' do
      expect(service_call_response).to eq(real_money: -amount, bonus: 0)
    end
  end

  context 'without real money on balance' do
    let!(:real_money_balance) do
      create(:balance, :real_money, amount: 0, wallet: wallet)
    end

    it 'calculates bonus amount' do
      expect(service_call_response).to eq(real_money: 0, bonus: -amount)
    end
  end

  context 'without balance money' do
    let!(:bonus_balance) do
      create(:balance, :bonus, amount: 0, wallet: wallet)
    end

    it 'calculates real amount' do
      expect(service_call_response).to eq(real_money: -amount, bonus: 0)
    end
  end
end
