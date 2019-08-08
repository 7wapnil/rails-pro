describe Webhooks::SafeCharge::PaymentsController, type: :controller do
  include_context 'safecharge_env'

  subject do
    post(:create, params: params)
  end

  let(:params) { response.merge(advanceResponseChecksum: signature) }
  let(:signature) { Digest::SHA256.hexdigest(signature_string) }
  let(:signature_string) do
    [
      ENV['SAFECHARGE_SECRET_KEY'],
      *response.slice(*signature_keys).values
    ].join
  end
  let(:signature_keys) do
    %i[
      totalAmount
      currency
      responseTimeStamp
      PPP_TransactionID
      Status
      productId
    ]
  end

  let(:response) do
    {
      totalAmount: amount,
      currency: Faker::Currency.code,
      PPP_TransactionID: SecureRandom.hex(5),
      ppp_status: payment_status,
      Status: status,
      payment_method: payment_method,
      userPaymentOptionId: Faker::Number.number(5).to_s,
      request_id: entry_request.id,
      responseTimeStamp: Time.zone.now.to_s,
      productId: Faker::Number.number(5).to_s
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

  context 'when payment approved' do
    before { subject }

    it 'change deposit status to succeeded' do
      expect(deposit.reload.status).to eq(Deposit::SUCCEEDED)
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
  end

  context 'when invalid signature' do
    let(:signature) { SecureRandom.hex(5) }

    it 'raise authentication error' do
      expect { subject }.to raise_error(Deposits::AuthenticationError)
    end

    it 'does not change deposit status' do
      subject
    rescue Deposits::AuthenticationError => _e
      expect(deposit.reload.status).to eq(Deposit::PENDING)
    end
  end
end
