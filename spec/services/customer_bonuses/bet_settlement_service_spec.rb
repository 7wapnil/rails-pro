describe CustomerBonuses::BetSettlementService do
  subject { described_class.call(bet) }

  before do
    allow(CustomerBonuses::RolloverCalculationService)
      .to receive(:call)
  end

  context 'completion' do
    it 'calls bonus completion when rollover becomes negative' do
      bonus = create(:customer_bonus, rollover_balance: -1)
      bet = create(:bet, :settled, customer_bonus: bonus)

      expect(CustomerBonuses::CompleteWorker).to receive(:perform_async)
      described_class.call(bet)
    end

    it 'calls bonus completion when rollover becomes zero' do
      bonus = create(:customer_bonus, rollover_balance: 0)
      bet = create(:bet, :settled, customer_bonus: bonus)

      expect(CustomerBonuses::CompleteWorker).to receive(:perform_async)
      described_class.call(bet)
    end

    it 'doesn\'t call bonus completion when rollover is positive' do
      bonus = create(:customer_bonus,
                     :with_positive_bonus_balance,
                     rollover_balance: 1)
      bet = create(:bet, :settled, customer_bonus: bonus)

      expect(CustomerBonuses::CompleteWorker).not_to receive(:perform_async)
      described_class.call(bet)
    end
  end

  context 'losing' do
    it 'doesn\'t lose when bonus money balance is positive' do
      customer_bonus = create(:customer_bonus, :with_positive_bonus_balance)
      bet = create(:bet, :settled, customer_bonus: customer_bonus)

      expect(customer_bonus)
        .not_to receive(:lose!)

      described_class.call(bet)
    end

    it 'doesn\'t lose when customer bonus is not active' do
      customer_bonus = create(:customer_bonus,
                              :with_empty_bonus_balance,
                              status: CustomerBonus::EXPIRED)
      bet = create(:bet, :settled, customer_bonus: customer_bonus)

      expect(customer_bonus)
        .not_to receive(:lose!)

      described_class.call(bet)
    end

    it 'doesn\'t lose when rollover requirements are reached' do
      customer_bonus = create(:customer_bonus,
                              :with_empty_bonus_balance,
                              rollover_balance: 0)
      bet = create(:bet, :settled, customer_bonus: customer_bonus)

      expect(customer_bonus)
        .not_to receive(:lose!)

      described_class.call(bet)
    end

    it 'doesn\'t lose when customer bonus has pending bets' do
      customer_bonus = create(:customer_bonus, :with_empty_bonus_balance)
      bet = create(:bet, :settled, customer_bonus: customer_bonus)

      create(:bet, :accepted, customer_bonus: customer_bonus) # pending bet

      expect(customer_bonus)
        .not_to receive(:lose!)

      described_class.call(bet)
    end

    it 'loses when the criteria is met' do
      customer_bonus = create(:customer_bonus, :with_empty_bonus_balance)
      bet = create(:bet, :settled, customer_bonus: customer_bonus)

      expect(customer_bonus)
        .to receive(:lose!)

      described_class.call(bet)
    end
  end
end
