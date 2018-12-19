describe BalanceCalculations::BetWithBonus do
  let(:bonus_amount) { 250.0 }
  let(:real_amount) { 750.0 }
  let(:amount) { 10 }
  let(:bonus_balance) { double('Balance', amount: bonus_amount) }
  let(:real_balance) { double('Balance', amount: real_amount) }
  let(:customer_bonus) { double('CustomerBonus', expired?: false) }
  let(:customer) { double('Customer', customer_bonus: customer_bonus) }
  let(:wallet) do
    double('Wallet',
           customer: customer,
           bonus_balance: bonus_balance,
           real_money_balance: real_balance)
  end

  subject(:service_call_response) { described_class.call(wallet, amount) }
  context 'with existent bonus balance and real money balance' do
    let(:calculations) { { real_money: 7.5, bonus: 2.5 } }
    it 'calculates ratio' do
      ratio = described_class.new(wallet, amount).ratio

      expect(ratio).to eq(0.75)
    end

    it 'calculates real and bonus amount' do
      expect(service_call_response).to include(calculations)
    end
  end

  context 'without bonus balance' do
    let(:calculations) { { real_money: amount, bonus: 0 } }
    before do
      allow(wallet).to receive(:bonus_balance) { nil }
    end

    it 'calculates ratio' do
      ratio = described_class.new(wallet, amount).ratio

      expect(ratio).to eq(1.0)
    end

    it 'calculates real and bonus money amount' do
      expect(service_call_response).to eq(calculations)
    end
  end

  context 'without active bonus' do
    let(:calculations) { { real_money: amount, bonus: 0 } }
    let(:customer) { double('Customer', customer_bonus: nil) }

    it 'calculates ratio' do
      ratio = described_class.new(wallet, amount).ratio

      expect(ratio).to eq(1)
    end

    it 'calculates real and bonus amount' do
      expect(service_call_response).to include(calculations)
    end
  end
end
