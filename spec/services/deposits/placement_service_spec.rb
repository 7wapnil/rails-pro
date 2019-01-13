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

  context 'with customer bonus' do
    before do
      service_call
    end

    it_behaves_like 'entries splitting with bonus' do
      let(:real_money_amount) { 100 }
      let(:bonus_amount) { amount * percentage / 100.0 }
    end
  end

  context 'without customer bonus' do
    before do
      CustomerBonus.destroy_all
      wallet.reload
      service_call
    end

    it_behaves_like 'entries splitting without bonus' do
      let(:real_money_amount) { 100 }
      let(:bonus_amount) { amount * percentage / 100.0 }
    end
  end
end
