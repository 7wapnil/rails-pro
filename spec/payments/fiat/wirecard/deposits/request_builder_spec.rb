describe Payments::Fiat::Wirecard::Deposits::RequestBuilder do
  include_context 'wirecard_env'
  include_context 'frozen_time'

  subject { described_class.call(transaction) }

  let(:transaction) do
    transaction_class.new(
      id: id,
      method: payment_method,
      customer: customer,
      currency_code: currency.code,
      amount: amount
    )
  end
  let(:id) { Faker::Number.number(5) }
  let(:customer) { create(:customer) }
  let(:amount) { Faker::Number.number(3) }
  let(:currency) { create(:currency) }
  let(:payment_method) { Payments::Methods::CREDIT_CARD }
  let(:transaction_class) { Payments::Transactions::Deposit }

  let(:expected_params) do
    {
      'payment': {
        'merchant-account-id': {
          'value': ENV['WIRECARD_MERCHANT_ACCOUNT_ID']
        },
        'request-id': "#{id}:#{timestamp}",
        'transaction-type': 'authorization',
        'requested-amount': {
          'value': amount,
          'currency': currency.code
        },
        'account-holder': {
          'first-name': customer.first_name,
          'last-name': customer.last_name
        },
        'payment-methods': {
          'payment-method': [
            { 'name': Payments::Fiat::Wirecard::Methods::CREDIT_CARD }
          ]
        },
        'redirect-url': "#{callback_url}?#{verification_parameters}"
      }
    }
  end
  let(:timestamp) { Time.zone.now }
  let(:callback_url) { "#{ENV['APP_HOST']}/webhooks/wirecard/payment" }
  let(:verification_parameters) { "request_id=#{id}&signature=#{signature}" }
  let(:signature) do
    OpenSSL::HMAC.hexdigest(
      hmac_algorithm,
      ENV['WIRECARD_SECRET_KEY'],
      id.to_s
    )
  end
  let(:hmac_algorithm) do
    Payments::Fiat::Wirecard::SignatureVerifier::SIGNATURE_ALGORITHM
  end

  context 'when transaction completed' do
    it 'generate valid wirecard request' do
      allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)

      expect(subject).to eq(expected_params)
    end
  end
end
