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

  context 'with existent bonus balance and real money balance' do
    it 'calculates ratio' do
      ratio = described_class.new(wallet, amount).ratio

      expect(ratio).to eq(0.75)
    end

    it 'calculates real money amount' do
      real_money = described_class.call(wallet, amount)[:real_money]

      expect(real_money).to eq(7.5)
    end

    it 'calculates bonus money amount' do
      real_money = described_class.call(wallet, amount)[:bonus]

      expect(real_money).to eq(2.5)
    end
  end

  context 'without bonus balance' do
    before do
      allow(wallet).to receive(:bonus_balance) { nil }
    end

    it 'calculates ratio' do
      ratio = described_class.new(wallet, amount).ratio

      expect(ratio).to eq(1.0)
    end

    it 'calculates real money amount' do
      real_money = described_class.call(wallet, amount)[:real_money]

      expect(real_money).to eq(amount)
    end
    it 'calculates bonus money amount' do
      bonus_money = described_class.call(wallet, amount)[:bonus]

      expect(bonus_money).to eq(0)
    end
  end

  context 'without active bonus' do
    let(:customer) { double('Customer', customer_bonus: nil) }

    it 'calculates ratio' do
      ratio = described_class.new(wallet, amount).ratio

      expect(ratio).to eq(1)
    end

    it 'calculates bonus amount' do
      bonus_money = described_class.call(wallet, amount)[:bonus]

      expect(bonus_money).to eq(0)
    end

    it 'calculates real amount' do
      real_money = described_class.call(wallet, amount)[:real_money]

      expect(real_money).to eq(amount)
    end
  end
end
