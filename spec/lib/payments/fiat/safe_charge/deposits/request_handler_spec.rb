# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::Deposits::RequestHandler do
  include_context 'safecharge_env'

  subject { described_class.call(transaction) }

  let(:namespace) { Payments::Fiat::SafeCharge::Deposits }

  let(:transaction) do
    ::Payments::Transactions::Deposit.new(
      id: entry_request.id,
      method: Payments::Methods::NETELLER,
      customer: entry_request.customer,
      currency_code: entry_request.currency.code,
      amount: entry_request.amount
    )
  end

  let(:customer) { create(:customer, :with_address) }
  let(:entry_request) { create(:entry_request, customer: customer) }
  let(:amount) { entry_request.amount }

  let(:deposit_url_response) do
    OpenStruct.new(
      'ok?': true,
      **redirect_url_payload.symbolize_keys
    )
  end

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
    allow_any_instance_of(namespace::RequestValidator).to receive(:call)
    allow_any_instance_of(Payments::Fiat::SafeCharge::Client)
      .to receive(:receive_deposit_redirect_url)
      .and_return(deposit_url_response)
  end

  context 'when request completed' do
    let(:redirect_url_payload) do
      JSON.parse(
        file_fixture('payments/fiat/safe_charge/payment_page_url.json').read
      )
    end
    let(:url) { 'url' }

    it 'returns deposit url' do
      expect(subject).to eq(url)
    end
  end

  context 'when something went wrong' do
    let(:fixture_path) do
      'payments/fiat/safe_charge/payment_page_url_failed.json'
    end
    let(:redirect_url_payload) { JSON.parse(file_fixture(fixture_path).read) }
    let(:message) { 'Invalid checksum' }

    it 'raise payment error' do
      expect { subject }
        .to raise_error(Payments::GatewayError, message)
    end
  end
end
