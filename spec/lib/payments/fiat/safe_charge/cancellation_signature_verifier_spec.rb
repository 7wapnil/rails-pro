# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::CancellationSignatureVerifier do
  include_context 'safecharge_env'

  subject { described_class.call(params) }

  let(:params) do
    ActionController::Parameters.new(
      signature: signature,
      request_id: request_id
    )
  end
  let(:signature) do
    OpenSSL::HMAC.hexdigest(
      hmac_algorithm,
      ENV['SAFECHARGE_SECRET_KEY'],
      signature_request_id.to_s
    )
  end
  let(:hmac_algorithm) do
    Payments::Fiat::SafeCharge::CancellationSignatureVerifier::
      SIGNATURE_ALGORITHM
  end
  let(:request_id) { Faker::Number.number(5) }
  let(:signature_request_id) { request_id }

  context 'when all params are valid' do
    it { is_expected.to be_truthy }
  end

  context 'when signature doesnt match request id' do
    let(:signature_request_id) { Faker::Number.number(3) }

    it { is_expected.to be_falsey }
  end
end
