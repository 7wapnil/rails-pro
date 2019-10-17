# frozen_string_literal: true

describe Payments::Fiat::SafeCharge::Deposits::RequestValidator do
  include_context 'safecharge_env'

  subject { described_class.call(deposit_params) }

  let(:namespace) { Payments::Fiat::SafeCharge }

  let(:deposit_params) do
    {
      merchantId: ENV['SAFECHARGE_MERCHANT_ID'],
      merchantSiteId: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
      userTokenId: customer.id,
      clientUniqueId: customer.id,
      clientRequestId: entry_request.id,
      currency: currency_code,
      amount: entry_request.amount,
      billingAddress: billing_address,
      paymentMethod: namespace::Methods::APMGW_NETELLER,
      timeStamp: Time.zone.now.to_i,
      checksum: checksum
    }
  end
  let(:billing_address) do
    {
      firstName: customer.first_name,
      lastName: customer.last_name,
      phone: customer.phone,
      city: customer.address.city,
      country: country_code,
      state: state_code,
      email: customer.email
    }
  end

  let(:customer) { create(:customer, :with_address) }
  let(:entry_request) { create(:entry_request, customer: customer) }
  let(:checksum) { Faker::Crypto.sha256 }
  let(:currency_code) { 'EUR' }
  let(:country_code) { 'CA' }
  let(:state_code) { 'MB' }

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
  end

  context 'valid' do
    before { subject }

    it { is_expected.to be_nil }
  end

  context 'mandatory fields presence' do
    let(:checksum) { nil }

    it 'raise error' do
      expect { subject }.to raise_error(::SafeCharge::InvalidParameterError)
    end
  end

  context 'unsupported currency' do
    let(:currency_code) { 'ZZZ' }

    it 'raise error' do
      expect { subject }.to raise_error(::SafeCharge::InvalidParameterError)
    end
  end

  context 'unsupported country' do
    let(:country_code) { 'ZZ' }

    it 'raise error' do
      expect { subject }.to raise_error(::SafeCharge::InvalidParameterError)
    end
  end
end
