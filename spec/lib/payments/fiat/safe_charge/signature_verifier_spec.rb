# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::SignatureVerifier do
  include_context 'safecharge_env'

  subject { described_class.call(params) }

  let(:params) { response.merge('advanceResponseChecksum' => signature) }
  let(:response) do
    {
      'totalAmount' => Faker::Number.number(2).to_s,
      'currency' => Faker::Currency.code,
      'responseTimeStamp' => Time.zone.now.to_s,
      'PPP_TransactionID' => SecureRandom.hex(5),
      'Status' => 'Created',
      'productId' => Faker::Number.number(5).to_s
    }
  end
  let(:signature) { Digest::SHA256.hexdigest(signature_string) }
  let(:signature_string) do
    [ENV['SAFECHARGE_SECRET_KEY'], *response.values].join
  end

  context 'when all params are valid' do
    it { is_expected.to be_truthy }
  end

  context 'when signature doesnt cover rest response' do
    let(:signature) { SecureRandom.hex(5) }

    it { is_expected.to be_falsey }
  end
end
