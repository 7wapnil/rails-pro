# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::OrderDetails::RequestHandler do
  include_context 'safecharge_env'
  include_context 'frozen_time'

  subject { described_class.call(approve_params) }

  let(:namespace) { Payments::Fiat::SafeCharge }

  let(:approve_params) do
    {
      transaction: OpenStruct.new(id: request_id),
      order_id: order_id
    }
  end
  let(:request_id) { Faker::Number.number(4) }
  let(:order_id) { '1' }

  let(:response) do
    OpenStruct.new(
      'ok?': true,
      **approve_payload.symbolize_keys
    )
  end
  let(:approve_payload) do
    JSON.parse(
      file_fixture(fixture_path).read
    )
  end

  before do
    allow_any_instance_of(::Payments::Fiat::SafeCharge::Client)
      .to receive(:receive_order_details)
      .and_return(response)
  end

  context 'succeeded request' do
    let(:fixture_path) { 'payments/fiat/safe_charge/order_details.json' }
    let(:message) { 'Expiration date has already passed.' }

    it 'returns error description' do
      expect(subject).to eq(message)
    end
  end

  context 'failed request' do
    let(:fixture_path) do
      'payments/fiat/safe_charge/order_details_failed.json'
    end
    let(:message) { 'Invalid checksum' }

    it 'returns reason message' do
      expect(subject).to eq(message)
    end
  end

  context 'API error' do
    let(:response) { OpenStruct.new('ok?': false) }
    let(:message) do
      "Fail during fetching error details for order id: #{order_id}"
    end

    it 'returns default message' do
      expect(subject).to eq(message)
    end
  end
end
