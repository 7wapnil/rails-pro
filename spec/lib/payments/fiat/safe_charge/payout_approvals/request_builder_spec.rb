# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::PayoutApprovals::RequestBuilder do
  include_context 'safecharge_env'
  include_context 'frozen_time'

  subject { described_class.call(approve_params) }

  let(:approve_params) do
    {
      transaction: OpenStruct.new(id: request_id),
      withdrawal_id: withdrawal_id
    }
  end
  let(:request_id) { Faker::Number.number(4) }
  let(:withdrawal_id) { Faker::Number.number(4) }

  let(:timestamp) { Time.zone.now.strftime(described_class::TIMESTAMP_FORMAT) }

  let(:checksum_string) do
    [
      ENV['SAFECHARGE_MERCHANT_ID'],
      ENV['SAFECHARGE_MERCHANT_SITE_ID'],
      withdrawal_id.to_s,
      request_id.to_s,
      timestamp,
      ENV['SAFECHARGE_SECRET_KEY']
    ].join
  end

  it 'returns request body' do
    expect(subject).to include(
      merchantId: ENV['SAFECHARGE_MERCHANT_ID'],
      merchantSiteId: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
      wdRequestId: withdrawal_id,
      merchantWDRequestId: request_id,
      timeStamp: timestamp,
      checksum: Digest::SHA256.hexdigest(checksum_string)
    )
  end
end
