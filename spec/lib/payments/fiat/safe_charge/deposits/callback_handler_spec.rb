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
      userPaymentOptionId: '2',
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
  let!(:wallet) do
    create(
      :wallet,
      real_money_balance: 0,
      currency: currency,
      customer: customer
    )
  end
  let(:mode) { Payments::Methods::NETELLER }

  let(:payment_options_payload) do
    JSON.parse(
      file_fixture('payments/fiat/safe_charge/get_user_UPOs.json').read
    )['paymentMethods']
  end

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
    allow(Customers::Summaries::BalanceUpdateWorker).to receive(:perform_async)
    allow_any_instance_of(::Payments::Fiat::SafeCharge::Client)
      .to receive(:receive_user_payment_options)
      .and_return(payment_options_payload)
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
      expect(wallet.reload.real_money_balance).to eq(amount.to_d)
    end

    it 'stores payment details' do
      expect(deposit.reload.details).to include(
        'user_payment_option_id' => '2',
        'name' => '1488228'
      )
    end
  end

  context 'when payment cancelled' do
    let(:status) { Payments::Webhooks::Statuses::CANCELLED }
    let(:payment_status) { Payments::Webhooks::Statuses::CANCELLED }

    before { subject }

    it 'change deposit status to failed' do
      expect(deposit.reload.status).to eq(Deposit::FAILED)
    end

    it 'does not change real balance' do
      expect(wallet.reload.real_money_balance).to be_zero
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

    it 'does not change real balance' do
      expect(wallet.reload.real_money_balance).to be_zero
    end
  end
end
