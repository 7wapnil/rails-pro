describe CustomerBonuses::BetSettlementService do
  subject { described_class.call(bet: bet) }

  context 'with positive rollover' do
    before { allow(CustomerBonuses::CompleteWorker).to receive(:perform_async) }

    let(:bet) { create(:bet, :settled, :won, customer_bonus: customer_bonus) }
    let(:customer_bonus) do
      create(:customer_bonus, rollover_initial_value: 100_000)
    end

    it 'does not call CustomerBonuses::Complete' do
      subject
      expect(CustomerBonuses::CompleteWorker)
        .not_to have_received(:perform_async)
    end
  end

  context 'with negative rollover' do
    before do
      allow(CustomerBonuses::CompleteWorker).to receive(:perform_async)
      allow(WalletEntry::AuthorizationService)
        .to receive(:call).and_return(create(:entry))
    end

    let(:bet) { create(:bet, :settled, :won, customer_bonus: customer_bonus) }
    let(:customer_bonus) do
      create(:customer_bonus, rollover_initial_value: -100_000)
    end

    it 'calls CustomerBonuses::Complete' do
      subject
      expect(CustomerBonuses::CompleteWorker).to have_received(:perform_async)
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
