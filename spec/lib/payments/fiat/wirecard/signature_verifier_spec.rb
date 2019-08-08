# frozen_string_literal: true

describe Payments::Fiat::Wirecard::SignatureVerifier do
  include_context 'wirecard_env'

  subject { described_class.call(params) }

  let(:params) do
    {
      signature: signature,
      request_id: request_id,
      'response-signature-base64' => base64_hmac,
      'response-base64' => response.to_json
    }
  end
  let(:signature) do
    OpenSSL::HMAC.hexdigest(
      hmac_algorithm,
      ENV['WIRECARD_SECRET_KEY'],
      signature_request_id.to_s
    )
  end
  let(:hmac_algorithm) do
    Payments::Fiat::Wirecard::SignatureVerifier::SIGNATURE_ALGORITHM
  end
  let(:request_id) { Faker::Number.number(5) }
  let(:signature_request_id) { request_id }
  let(:base64_hmac) { Base64.encode64(signature_hmac) }
  let(:signature_hmac) do
    OpenSSL::HMAC.digest(
      hmac_algorithm,
      ENV['WIRECARD_SECRET_KEY'],
      signature_response.to_json
    )
  end
  let(:signature_response) { response }
  let(:response) do
    { status: 'rejected' }
  end

  context 'when all params are valid' do
    it { is_expected.to be_truthy }
  end

  context 'when base64 fields are empty' do
    let(:params) do
      {
        signature: signature,
        request_id: request_id
      }
    end

    context 'when our signature covers request id' do
      it { is_expected.to be_truthy }
    end

    context 'when request id is empty' do
      let(:request_id) { nil }
      let(:signature_request_id) { Faker::Number.number(5) }

      it { is_expected.to be_falsey }
    end

    context 'when our signature is empty' do
      let(:signature_request_id) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when our signature doest not cover request id' do
      let(:request_id) { Faker::Number.number(4) }
      let(:signature_request_id) { Faker::Number.number(5) }

      it { is_expected.to be_falsey }
    end
  end

  context 'when received data does not cover their signature' do
    let(:signature_response) do
      { status: 'failed' }
    end

    it { is_expected.to be_falsey }
  end
end
