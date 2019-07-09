describe CustomerBonuses::BetSettlementService do
  subject { described_class.call(bet) }

  context 'completion' do
    it 'calls bonus completion when rollover becomes negative' do
      allow(CustomerBonuses::RolloverCalculationService)
        .to receive(:call)

      bonus = create(:customer_bonus, rollover_balance: -1)
      bet = create(:bet, :settled, customer_bonus: bonus)

      expect(CustomerBonuses::CompleteWorker).to receive(:perform_async)
      described_class.call(bet)
    end

    it 'calls bonus completion when rollover becomes zero' do
      allow(CustomerBonuses::RolloverCalculationService)
        .to receive(:call)

      bonus = create(:customer_bonus, rollover_balance: 0)
      bet = create(:bet, :settled, customer_bonus: bonus)

      expect(CustomerBonuses::CompleteWorker).to receive(:perform_async)
      described_class.call(bet)
    end

    it 'doesn\'t call bonus completion when rollover is positive' do
      allow(CustomerBonuses::RolloverCalculationService)
        .to receive(:call)

      bonus = create(:customer_bonus, rollover_balance: 1)
      bet = create(:bet, :settled, customer_bonus: bonus)

      expect(CustomerBonuses::CompleteWorker).not_to receive(:perform_async)
      described_class.call(bet)
    end
  end

  context 'with negative bonus balance amount' do
    let(:bonus_balance) { create(:balance, :bonus, amount: -10) }
    let(:wallet) { create(:wallet, bonus_balance: bonus_balance) }
    let(:customer_bonus) { create(:customer_bonus, wallet: wallet) }
    let(:bet) do
      create(:bet, :settled, :won, customer_bonus: customer_bonus,
                                   customer: wallet.customer)
    end

    before { subject }

    it 'marks customer bonus as lost' do
      expect(customer_bonus).to be_lost
    end
  end
end
