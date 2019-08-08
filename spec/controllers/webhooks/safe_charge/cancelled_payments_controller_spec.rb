describe Webhooks::SafeCharge::CancelledPaymentsController, type: :controller do
  include_context 'safecharge_env'

  subject do
    get(:show, params: params)
  end

  let(:params) { response.merge(signature: signature) }
  let(:signature) do
    OpenSSL::HMAC.hexdigest(
      Payments::Fiat::SafeCharge::CancellationSignatureVerifier::
        SIGNATURE_ALGORITHM,
      ENV['SAFECHARGE_SECRET_KEY'],
      entry_request.id.to_s
    )
  end

  let(:response) do
    {
      totalAmount: Faker::Number.number(2).to_s,
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
  let(:payment_method) { Payments::Fiat::SafeCharge::Methods::APMGW_NETELLER }
  let(:status) { Payments::Webhooks::Statuses::CANCELLED }
  let(:payment_status) { Payments::Webhooks::Statuses::CANCELLED }

  let(:customer) { create(:customer) }
  let(:entry_request) do
    create(
      :entry_request,
      mode: mode,
      customer: customer,
      currency: currency,
      origin: deposit
    )
  end
  let(:deposit) { create(:deposit) }
  let(:currency) { create(:currency, :primary) }
  let(:wallet) { create(:wallet, currency: currency, customer: customer) }
  let(:mode) { Payments::Methods::NETELLER }

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
    allow(Customers::Summaries::BalanceUpdateWorker).to receive(:perform_async)
  end

  context 'when payment cancelled' do
    before { subject }

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
