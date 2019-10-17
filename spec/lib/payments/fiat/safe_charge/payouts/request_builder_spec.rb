# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::Payouts::RequestBuilder do
  include_context 'safecharge_env'
  include_context 'frozen_time'

  subject { described_class.call(transaction: transaction) }

  let(:transaction) do
    ::Payments::Transactions::Payout.new(
      id: entry_request.id,
      method: Payments::Methods::NETELLER,
      withdrawal: create(:withdrawal),
      details: { 'user_payment_option_id' => payment_option_id },
      customer: entry_request.customer,
      currency_code: entry_request.currency.code,
      amount: entry_request.amount
    )
  end

  let(:customer) { create(:customer) }
  let(:entry_request) { create(:entry_request, customer: customer) }
  let(:amount) { entry_request.amount }
  let(:payment_option_id) { Faker::Number.number(6).to_s }
  let(:timestamp) { Time.zone.now.strftime(described_class::TIMESTAMP_FORMAT) }

  let(:checksum_string) do
    [
      ENV['SAFECHARGE_MERCHANT_ID'],
      ENV['SAFECHARGE_MERCHANT_SITE_ID'],
      customer.id.to_s,
      payment_option_id.to_s,
      entry_request.amount.abs.to_s,
      entry_request.currency.code,
      entry_request.id.to_s,
      entry_request.id.to_s,
      timestamp,
      ENV['SAFECHARGE_SECRET_KEY']
    ].join
  end

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
  end

  it 'returns request body' do
    expect(subject).to include(
      merchantId: ENV['SAFECHARGE_MERCHANT_ID'],
      merchantSiteId: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
      userTokenId: customer.id,
      userPMId: payment_option_id,
      amount: entry_request.amount.abs,
      currency: entry_request.currency.code,
      merchantWDRequestId: entry_request.id,
      merchantUniqueId: entry_request.id,
      timeStamp: timestamp,
      checksum: Digest::SHA256.hexdigest(checksum_string)
    )
  end
end
