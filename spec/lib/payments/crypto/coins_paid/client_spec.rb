# frozen_string_literal: true

describe ::Payments::Crypto::CoinsPaid::Client do
  subject { described_class.new }

  let(:wallet) do
    create(:wallet, :crypto, :with_crypto_address)
  end
  let(:customer) { wallet.customer }
  let(:response_double) { double }
  let(:parsed_response) { JSON.parse(response) }

  before do
    allow(described_class).to receive(:post).and_return(response_double)
    allow(response_double).to receive(:body)
    allow(JSON).to receive(:parse).and_return(parsed_response)
  end

  context '#generate_address' do
    let(:request_header) { { 'X-Processing-Signature': signature } }
    let(:signature) do
      Payments::Crypto::CoinsPaid::SignatureService
        .call(data: request_body.to_json)
    end
    let(:request_body) do
      {
        currency: ::Payments::Crypto::CoinsPaid::Currency::BTC_CODE,
        foreign_id: customer.id.to_s
      }
    end

    let(:response) do
      file_fixture('payments/crypto/coins_paid/client_get_address.json').read
    end

    it 'generates crypto address' do
      expect(subject.generate_address(customer))
        .to eq(parsed_response.dig('data', 'address'))
    end

    it 'makes correct request' do
      expect(described_class)
        .to receive(:post)
        .with(described_class::DEPOSIT_ROUTE, body: request_body.to_json)

      subject.generate_address(customer)
    end

    it 'sets correct headers' do
      expect(described_class)
        .to receive(:headers)
        .with(request_header)

      subject.generate_address(customer)
    end
  end

  context '#fetch_limits' do
    let(:response) do
      file_fixture('payments/crypto/coins_paid/client_get_address.json').read
    end
    let(:request_header) do
      {
        'X-Processing-Signature':
          Payments::Crypto::CoinsPaid::SignatureService.call
      }
    end

    it 'generates crypto address' do
      expect(subject.fetch_limits)
        .to eq(parsed_response.dig('data'))
    end

    it 'makes correct request' do
      expect(described_class)
        .to receive(:post).with(described_class::LIMITS_ROUTE)

      subject.fetch_limits
    end

    it 'sets correct headers' do
      expect(described_class)
        .to receive(:headers).with(request_header)

      subject.fetch_limits
    end
  end
end
