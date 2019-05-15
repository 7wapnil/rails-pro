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
  let(:original_bonus) { create(:bonus, percentage: percentage) }
  let(:customer_bonus) do
    create(:customer_bonus,
           customer: customer,
           percentage: percentage,
           wallet: wallet,
           rollover_balance: 20,
           rollover_multiplier: rollover_multiplier,
           original_bonus: original_bonus)
  end
  let(:entry_request) do
    EntryRequests::Factories::Deposit.call(
      wallet: wallet,
      amount: amount,
      customer_bonus: customer_bonus,
      mode: EntryRequest::SKRILL
    )
  end
  let(:service_call) { described_class.call(entry_request: entry_request) }

  before do
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
    let(:deposit_limit) do
      create(:deposit_limit, currency: wallet.currency,
                             customer: customer,
                             value: amount - 1)
    end

    it 'when do not pass deposit limit' do
      deposit_limit
      service_call
      wallet.reload

      expect(wallet.bonus_balance).to be_nil
    end
  end

  context 'with customer bonus' do
    let(:created_deposit_request) { entry_request.origin }

    before { service_call }

    it_behaves_like 'entries splitting with bonus' do
      let(:real_money_amount) { 100 }
      let(:bonus_amount) { amount * percentage / 100.0 }
    end

    it 'activates customer bonus' do
      # TODO: REFACTOR AFTER CUSTOMER BONUS IMPLEMENTATION
      allow(customer_bonus).to receive(:active?).and_return(true)
      expect(wallet.customer_bonus).to be_active
    end

    it 'creates deposit request with customer bonus assigned' do
      expect(created_deposit_request.customer_bonus).to eq(customer_bonus)
    end

    it 'applies customer bonus only once' do
      expect { service_call }.not_to change(BalanceEntryRequest.bonus, :count)
    end
  end

  context 'without customer bonus' do
    let(:customer_bonus) {}

    before do
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
