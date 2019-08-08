# frozen_string_literal: true

describe Payments::Fiat::Wirecard::Deposits::RequestHandler do
  include_context 'wirecard_env'

  subject { described_class.call(transaction: transaction) }

  let(:transaction) do
    Payments::Transactions::Deposit.new(
      id: Faker::Number.number(5),
      method: Payments::Methods::CREDIT_CARD,
      customer: create(:customer),
      currency_code: create(:currency).code,
      amount: Faker::Number.number(3)
    )
  end

  let(:httparty_response) do
    instance_double(
      HTTParty::Response,
      parsed_response: {
        'payment-redirect-url' => url
      }
    )
  end
  let(:url) { 'https://host.com?some_params' }

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
  end

  context 'when request completed' do
    before do
      allow(Payments::Fiat::Wirecard::Client)
        .to receive(:post)
        .and_return(httparty_response)
    end

    it 'returns redirect url' do
      expect(subject).to eq(url)
    end
  end

  context 'when something went wrong' do
    before do
      allow(Payments::Fiat::Wirecard::Client)
        .to receive(:post)
        .and_raise(HTTParty::ResponseError, :response)
    end

    it 'raise gateway error' do
      expect { subject }.to raise_error(Payments::GatewayError)
    end
  end
end
