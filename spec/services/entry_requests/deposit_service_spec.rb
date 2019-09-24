# frozen_string_literal: true

describe EntryRequests::DepositService do
  let(:customer) { create(:customer) }
  let(:currency) { create(:currency) }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:percentage) { 25 }
  let(:amount) { 100 }
  let(:rollover_multiplier) { 5 }
  let(:wallet) do
    create(:wallet, :empty, customer: customer, currency: currency)
  end
  let(:original_bonus) { create(:bonus, percentage: percentage) }
  let(:customer_bonus) do
    create(:customer_bonus, :initial,
           customer: customer,
           percentage: percentage,
           wallet: wallet,
           rollover_balance: 20,
           rollover_multiplier: rollover_multiplier,
           original_bonus: original_bonus)
  end
  let(:transaction) do
    Payments::Transactions::Deposit.new(
      method: EntryRequest::SKRILL,
      customer: customer,
      amount: amount,
      comment: Faker::Lorem.sentence,
      initiator: customer,
      currency_code: currency.code
    )
  end
  let(:entry_request) do
    EntryRequests::Factories::Deposit.call(
      transaction: transaction,
      customer_bonus: customer_bonus
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
      expect(wallet.bonus_balance).to eq(25)
    end

    it 'increases real money balance amount' do
      expect(wallet.real_money_balance).to eq(amount)
    end
  end

  context "don't affect bonus balance" do
    let!(:deposit_limit) do
      create(:deposit_limit, currency: wallet.currency,
                             customer: customer,
                             value: amount - 1)
    end

    it 'when do not pass deposit limit' do
      service_call
    rescue ::Payments::FailedError
      wallet.reload

      expect(wallet.bonus_balance).to be_zero
    end
  end

  context 'with customer bonus' do
    let(:created_deposit) { entry_request.origin }

    before { service_call }

    it 'creates deposit request with customer bonus assigned' do
      expect(created_deposit.customer_bonus).to eq(customer_bonus)
    end

    it 'applies customer bonus only once' do
      expect { service_call }.not_to change(EntryRequest, :count)
    end

    it 'activates customer bonus' do
      service_call

      expect(customer_bonus.reload).to have_attributes(
        entry_id: entry_request.entry.id,
        status: CustomerBonus::ACTIVE
      )
    end
  end

  context 'with failed entry request' do
    before { entry_request.failed! }

    it 'does not proceed' do
      service_call
    rescue ::Payments::FailedError
      expect(WalletEntry::AuthorizationService).not_to receive(:call)
    end

    it 'fails customer bonus' do
      service_call
    rescue ::Payments::FailedError
      expect(customer_bonus.reload).to have_attributes(
        entry_id: nil,
        status: CustomerBonus::FAILED
      )
    end
  end
end
