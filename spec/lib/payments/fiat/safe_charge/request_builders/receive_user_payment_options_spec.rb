# frozen_string_literal: true

namespace = Payments::Fiat::SafeCharge::RequestBuilders

describe namespace::ReceiveUserPaymentOptions do
  include_context 'safecharge_env'
  include_context 'frozen_time'

  subject { described_class.call(customer: customer) }

  let(:customer) { create(:customer) }
  let(:timestamp) { Time.zone.now }

  let(:checksum_string) do
    [
      ENV['SAFECHARGE_MERCHANT_ID'],
      ENV['SAFECHARGE_MERCHANT_SITE_ID'],
      customer.id.to_s,
      timestamp.to_i.to_s,
      timestamp.strftime(described_class::TIMESTAMP_FORMAT),
      ENV['SAFECHARGE_SECRET_KEY']
    ].join
  end

  it 'returns request body' do
    expect(subject).to include(
      merchantId: ENV['SAFECHARGE_MERCHANT_ID'],
      merchantSiteId: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
      userTokenId: customer.id,
      clientRequestId: timestamp.to_i,
      timeStamp: timestamp.strftime(described_class::TIMESTAMP_FORMAT),
      checksum: Digest::SHA256.hexdigest(checksum_string)
    )
  end
end
