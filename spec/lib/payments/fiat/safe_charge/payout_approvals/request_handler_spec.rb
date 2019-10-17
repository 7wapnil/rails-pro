# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::PayoutApprovals::RequestHandler do
  include_context 'safecharge_env'
  include_context 'frozen_time'

  subject { described_class.call(approve_params) }

  let(:namespace) { Payments::Fiat::SafeCharge }

  let(:approve_params) do
    {
      transaction: OpenStruct.new(id: request_id),
      withdrawal_id: withdrawal_id
    }
  end
  let(:request_id) { Faker::Number.number(4) }
  let(:withdrawal_id) { Faker::Number.number(4) }

  let(:response) do
    OpenStruct.new(
      'ok?': true,
      **approve_payload.deep_symbolize_keys
    )
  end

  before do
    allow_any_instance_of(::Payments::Fiat::SafeCharge::Client)
      .to receive(:approve_payout)
      .and_return(response)
  end

  context 'succeeded request' do
    let(:approve_payload) do
      JSON.parse(
        file_fixture('payments/fiat/safe_charge/approve.json').read
      )
    end

    it 'returns true' do
      expect(subject).to be_truthy
    end
  end

  context 'failed request' do
    let(:approve_payload) do
      JSON.parse(
        file_fixture('payments/fiat/safe_charge/approve_failed.json').read
      )
    end
    let(:message) { Faker::Lorem.sentence }

    before do
      allow_any_instance_of(namespace::OrderDetails::RequestHandler)
        .to receive(:call)
        .and_return(message)
    end

    it 'raises error with error description' do
      expect { subject }.to raise_error(SafeCharge::ApprovingError, message)
    end
  end

  context 'failed request with external reason' do
    let(:approve_payload) do
      JSON.parse(
        file_fixture('payments/fiat/safe_charge/approve_error.json').read
      )
    end
    let(:message) { 'Invalid checksum' }

    it 'raises error with reason message' do
      expect { subject }.to raise_error(SafeCharge::ApprovingError, message)
    end
  end
end
