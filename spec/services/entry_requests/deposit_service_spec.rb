# frozen_string_literal: true

describe EntryRequests::DepositService do
  let(:customer) { create(:customer) }
  let(:currency) { create(:currency) }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:percentage) { 25 }
  let(:amount) { 100 }
  let(:rollover_multiplier) { 5 }
  let(:wallet) do
    create(:wallet, customer: customer, currency: currency, amount: 0.0)
  end
  let(:entry_request) do
    EntryRequests::Factories::Deposit.call(
      wallet: wallet, amount: amount, mode: EntryRequest::SKRILL
    )
  end
  let(:service_call) { described_class.call(entry_request: entry_request) }

  before do
    create(:customer_bonus,
           customer: customer,
           percentage: percentage,
           wallet: wallet,
           rollover_balance: 20,
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
      wallet.customer.active_bonus.update_attributes(min_deposit: amount + 1)
      service_call
      wallet.reload

      expect(wallet.bonus_balance).to be_nil
    end
  end

  it 'closes customer bonus if expired' do
    bonus = wallet.customer_bonus
    allow(bonus).to receive(:expired?).and_return(true)
    service_call

    expect(entry_request).to have_attributes(
      status: EntryRequest::FAILED,
      result: { 'message' => I18n.t('errors.messages.bonus_expired') }
    )
  end

  context 'with customer bonus' do
    before do
      service_call
    end

    it_behaves_like 'entries splitting with bonus' do
      let(:real_money_amount) { 100 }
      let(:bonus_amount) { amount * percentage / 100.0 }
    end

    it 'attaches entry to the customer bonus' do
      expect(wallet.active_bonus.entry).to be_instance_of(Entry)
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

    it_behaves_like 'entries splitting without bonus' do
      let(:real_money_amount) { 100 }
      let(:bonus_amount) { amount * percentage / 100.0 }
    end
  end

  context 'with failed entry request' do
    before { entry_request.failed! }

    it 'does not proceed' do
      service_call
      expect(WalletEntry::AuthorizationService).not_to receive(:call)
    end
  end
end
