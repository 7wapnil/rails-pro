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
      customer = create(:customer)
      wallet = create(:wallet, customer: customer)
      bonus = create(:customer_bonus,
                     wallet: wallet,
                     customer: customer,
                     rollover_balance: 1)
      bet = create(:bet, :settled, customer_bonus: bonus)

      create(:balance, :bonus, wallet: wallet)

      expect(CustomerBonuses::CompleteWorker).not_to receive(:perform_async)
      described_class.call(bet)
    end
  end

  context 'losing' do
    it 'doesn\'t lose when bonus money balance is positive' do
      customer = create(:customer)
      wallet = create(:wallet, customer: customer)
      customer_bonus = create(:customer_bonus,
                              wallet: wallet,
                              customer: customer)
      bet = create(:bet, :settled, customer_bonus: customer_bonus)

      create(:balance, :bonus, wallet: wallet, amount: 10)

      expect(customer_bonus)
        .not_to receive(:lose!)

      described_class.call(bet)
    end

    it 'doesn\'t lose when customer bonus is not active' do
      customer = create(:customer)
      wallet = create(:wallet, customer: customer)
      customer_bonus = create(:customer_bonus,
                              status: CustomerBonus::EXPIRED,
                              wallet: wallet,
                              customer: customer)
      bet = create(:bet, :settled, customer_bonus: customer_bonus)

      create(:balance, :bonus, wallet: wallet, amount: 0)

      expect(customer_bonus)
        .not_to receive(:lose!)

      described_class.call(bet)
    end

    it 'doesn\'t lose when rollover requirements are reached' do
      customer = create(:customer)
      wallet = create(:wallet, customer: customer)
      customer_bonus = create(:customer_bonus,
                              wallet: wallet,
                              customer: customer,
                              rollover_balance: 0)
      bet = create(:bet, :settled, customer_bonus: customer_bonus)

      create(:balance, :bonus, wallet: wallet, amount: 0)

      expect(customer_bonus)
        .not_to receive(:lose!)

      described_class.call(bet)
    end

    it 'doesn\'t lose when customer bonus has pending bets' do
      customer = create(:customer)
      wallet = create(:wallet, customer: customer)
      customer_bonus = create(:customer_bonus,
                              wallet: wallet,
                              customer: customer)
      bet = create(:bet, :settled, customer_bonus: customer_bonus)

      create(:balance, :bonus, wallet: wallet, amount: 0)
      create(:bet, :accepted, customer_bonus: customer_bonus) # pending bet

      expect(customer_bonus)
        .not_to receive(:lose!)

      described_class.call(bet)
    end

    it 'loses when the criteria is met' do
      customer = create(:customer)
      wallet = create(:wallet, customer: customer)
      customer_bonus = create(:customer_bonus,
                              wallet: wallet,
                              customer: customer)
      bet = create(:bet, :settled, customer_bonus: customer_bonus)

      create(:balance, :bonus, wallet: wallet, amount: 0)

      expect(customer_bonus)
        .to receive(:lose!)

      described_class.call(bet)
    end
  end
end
