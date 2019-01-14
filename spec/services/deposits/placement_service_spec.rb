describe Deposits::PlacementService do
  let(:customer) { create(:customer) }
  let(:currency) { create(:currency) }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:percentage) { 25 }
  let(:amount) { 100 }
  let(:rollover_multiplier) { 5 }
  let(:wallet) do
    create(:wallet, customer: customer, currency: currency, amount: 0)
  end
  let(:real_balance_request) { BalanceEntryRequest.real_money.first }
  let(:bonus_balance_request) { BalanceEntryRequest.bonus.first }
  let(:service_call) { described_class.call(wallet, amount) }

  before do
    create(:customer_bonus,
           customer: customer,
           percentage: percentage,
           wallet: wallet,
           rollover_multiplier: rollover_multiplier)
    allow(EntryCurrencyRule).to receive(:find_by!) { rule }
    allow(Currency).to receive(:find_by!) { currency }
  end

  context 'increase amount' do
    before do
      service_call
      wallet.reload
    end

    it 'increases wallet amount' do
      expect(wallet.amount).to eq(125)
    end

    it 'increases bonus money balance amount' do
      expect(wallet.bonus_balance.amount).to eq(25)
    end

    it 'increases real money balance amount' do
      expect(wallet.real_money_balance.amount).to eq(amount)
    end
  end

  context "don't affect bonus balance" do
    it 'when do not pass deposit limit' do
      wallet.customer.customer_bonus.update_attributes(min_deposit: amount + 1)
      service_call
      wallet.reload

      expect(wallet.bonus_balance).to be_nil
    end
  end

  it 'closes customer bonus if expired' do
    bonus = wallet.customer_bonus
    allow(bonus).to receive(:expired?).and_return(true)

    expect(bonus).to receive(:close!)

    service_call
  end

  context 'with customer bonus' do
    let(:calculated_percentage) { amount * percentage / 100.0 }

    before do
      service_call
    end

    it 'creates balance entry requests for real and bonus balances' do
      kinds = BalanceEntryRequest.pluck(:kind)

      expect(kinds).to match_array([Balance::REAL_MONEY, Balance::BONUS])
    end

    it 'assigns correct balance entry request real money amount' do
      expect(real_balance_request.amount).to eq(amount)
    end

    it 'assigns correct balance entry request bonus money amount' do
      expect(bonus_balance_request.amount).to eq(calculated_percentage)
    end

    it 'attaches entry to the customer bonus' do
      expect(wallet.customer_bonus.source).to be_instance_of(Entry)
    end

    it 'applies customer bonus only once' do
      expect { service_call }.not_to change(BalanceEntryRequest.bonus, :count)
    end
  end

  context 'without customer bonus' do
    before do
      CustomerBonus.destroy_all
      wallet.reload
      service_call
    end

    it 'creates balance entry request only for real money' do
      kinds = BalanceEntryRequest.pluck(:kind)

      expect(kinds).to match_array([Balance::REAL_MONEY])
    end

    it 'assigns correct balance entry request real money amount' do
      expect(real_balance_request.amount).to eq(amount)
    end
  end
end
