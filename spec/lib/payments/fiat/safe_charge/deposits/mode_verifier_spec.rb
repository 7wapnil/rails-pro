# frozen_string_literal: true

describe ::Payments::Fiat::SafeCharge::Deposits::ModeVerifier do
  let(:service_call) { described_class.call(params) }

  let!(:entry_request) { create(:entry_request) }
  let(:params) do
    {
      payment_method_code: payment_method_code,
      entry_request:       entry_request
    }
  end

  context 'with valid params' do
    let(:payment_method_code) { ::Payments::Fiat::SafeCharge::Methods::CC_CARD }

    it 'do not raise error' do
      expect { service_call }.not_to raise_error
    end
  end

  context 'with invalid payment method' do
    let(:payment_method_code) { Faker::Lorem.word }

    let(:message) do
      "Payment method '#{payment_method_code}' is not implemented"
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'raises unimplemented error and fails entry request' do
      expect { service_call }.to raise_error(message)
      expect(entry_request.status).to eq EntryRequest::FAILED
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
