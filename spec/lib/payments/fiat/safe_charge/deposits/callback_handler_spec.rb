# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::Deposits::CallbackHandler do
  include_context 'safecharge_env'

  subject { described_class.call(response) }

  let(:response) do
    {
      totalAmount: amount,
      currency: Faker::Currency.code,
      PPP_TransactionID: SecureRandom.hex(5),
      ppp_status: payment_status,
      Status: status,
      payment_method: payment_method,
      userPaymentOptionId: Faker::Number.number(5).to_s,
      request_id: entry_request.id
    }
  end
  let(:amount) { Faker::Number.number(2).to_s }
  let(:payment_method) { Payments::Fiat::SafeCharge::Methods::APMGW_NETELLER }
  let(:status) { Payments::Fiat::SafeCharge::Statuses::APPROVED }
  let(:payment_status) { Payments::Fiat::SafeCharge::Statuses::OK }

  let(:customer) { create(:customer) }
  let(:entry_request) do
    create(
      :entry_request,
      amount: amount,
      mode: mode,
      customer: customer,
      currency: currency,
      origin: deposit
    )
  end
  let(:deposit) { create(:deposit) }
  let(:currency) { create(:currency, :primary) }
  let(:wallet) { create(:wallet, currency: currency, customer: customer) }
  let(:entry) do
    create(:entry, kind: Entry::DEPOSIT, amount: amount, wallet: wallet)
  end
  let(:mode) { Payments::Methods::NETELLER }

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
    allow(Customers::Summaries::BalanceUpdateWorker).to receive(:perform_async)
  end

  context 'when entry request has different payment method' do
    let(:mode) { Payments::Methods::SKRILL }

    before { subject }

    it 'change entry request mode to payment mode' do
      expect(entry_request.reload.mode).to eq(Payments::Methods::NETELLER)
    end
  end

  context 'when payment approved' do
    before { subject }

    it 'change deposit status to succeeded' do
      expect(deposit.reload.status).to eq(Deposit::SUCCEEDED)
    end

    it 'change balance' do
      expect(wallet.reload.real_money_balance.amount).to eq(amount.to_d)
    end

    it 'store payment details' do
      expect(deposit.reload.details).to include('account_id')
    end
  end

  context 'when payment cancelled' do
    let(:status) { Payments::Webhooks::Statuses::CANCELLED }
    let(:payment_status) { Payments::Webhooks::Statuses::CANCELLED }

    before { subject }

    it 'change deposit status to failed' do
      expect(deposit.reload.status).to eq(Deposit::FAILED)
    end

    it 'does not create real balance' do
      expect(wallet.reload.real_money_balance).to be_nil
    end
  end

  context 'when payment failed' do
    let(:status) { Payments::Webhooks::Statuses::FAILED }
    let(:payment_status) { Payments::Webhooks::Statuses::FAILED }

    before do
      subject
    rescue Payments::TechnicalError => _e
    end

    it 'change deposit status to failed' do
      expect(deposit.reload.status).to eq(Deposit::FAILED)
    end

    it 'does not create real balance' do
      expect(wallet.reload.real_money_balance).to be_nil
    end
  end
end
