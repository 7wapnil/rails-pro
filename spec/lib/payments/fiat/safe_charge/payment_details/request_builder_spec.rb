# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::PaymentDetails::RequestBuilder do
  include_context 'safecharge_env'
  include_context 'frozen_time'

  subject { described_class.call(entry_request: entry_request) }

  let(:entry_request) { create(:entry_request) }
  let(:customer) { entry_request.customer }
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

  context 'when iDebit deposit' do
    let(:entry_request) { create(:entry_request, mode: EntryRequest::IDEBIT) }

    it 'returns expanded userTokenId' do
      expect(subject[:userTokenId]).to eq("000#{customer.id}")
    end
  end
end
