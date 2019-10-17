# frozen_string_literal: true

describe ::Payments::Fiat::SafeCharge::Deposits::RequestBuilder do
  include_context 'safecharge_env'

  subject { described_class.call(transaction) }

  let(:transaction) do
    ::Payments::Transactions::Deposit.new(
      id: entry_request.id,
      method: Payments::Methods::CREDIT_CARD,
      customer: entry_request.customer,
      currency_code: entry_request.currency.code,
      amount: entry_request.amount
    )
  end
  let(:checksum_keys) do
    %i[
      merchantId
      merchantSiteId
      clientRequestId
      amount
      currency
      timeStamp
    ]
  end

  let(:customer) { create(:customer, :with_address) }
  let(:entry_request) { create(:entry_request, customer: customer) }
  let(:amount) { entry_request.amount }

  it 'appends SafeCharge keys' do
    expect(subject)
      .to include(
        merchantId: merchant_id,
        merchantSiteId: merchant_site_id
      )
  end

  context 'other mandatory parameters' do
    let(:currency) { entry_request.currency }
    let(:time_stamp) do
      Time.zone.now.strftime(described_class::TIMESTAMP_FORMAT)
    end

    let(:item_name) do
      "Deposit #{amount} to your #{currency.code} wallet on #{brand_name}"
    end

    include_context 'frozen_time'

    it 'are appended' do
      expect(subject)
        .to include(
          timeStamp: time_stamp,
          clientUniqueId: customer.id,
          clientRequestId: entry_request.id,
          currency: currency.code,
          userTokenId: customer.id,
          amount: amount
        )
    end
  end

  context 'customer info' do
    let(:address) { customer.address }
    let(:address_fields) { subject.fetch(:billingAddress, {}) }

    it 'are appended' do
      expect(address_fields)
        .to include(
          firstName: customer.first_name,
          lastName: customer.last_name,
          email: customer.email,
          phone: customer.phone,
          address: address.street_address,
          city: address.city,
          country: address.country_code,
          state: address.state_code,
          zip: address.zip_code
        )
    end

    # TODO: remove when states would be handled on back-end
    context 'state' do
      before { address.country = ISO3166::Country.new('UA').to_s }

      it 'is ignored when set for country without states' do
        expect(address_fields[:state]).to be_nil
      end
    end
  end

  context 'additional parameters' do
    it 'includes native' do
      expect(subject[:isNative]).to eq(described_class::IS_NATIVE)
    end

    it 'includes filter mode' do
      expect(subject[:paymentMethodMode]).to eq(described_class::FILTER_MODE)
    end
  end

  context 'url parameters', routes: true do
    let(:notification) { subject[:urlDetails] }

    let(:webhook_url) do
      webhooks_safe_charge_payment_url(
        host: app_host,
        protocol: web_protocol,
        request_id: transaction.id
      )
    end
    let(:cancellation_signature) do
      OpenSSL::HMAC.hexdigest('sha256', secret_key, transaction.id.to_s)
    end
    let(:cancellation_redirection_url) do
      webhooks_safe_charge_payment_cancel_url(
        host: app_host,
        protocol: web_protocol,
        request_id: transaction.id,
        signature: cancellation_signature
      )
    end

    it 'are appended' do
      expect(notification)
        .to include(
          successUrl: webhook_url,
          failureUrl: webhook_url,
          pendingUrl: webhook_url,
          backUrl: cancellation_redirection_url,
          notificationUrl: webhook_url
        )
    end
  end

  context 'checksum' do
    let(:squash_parameters) { subject.slice(*checksum_keys).values.join }
    let(:checksum) do
      Digest::SHA256.hexdigest("#{squash_parameters}#{secret_key}")
    end

    it 'is appended' do
      expect(subject[:checksum]).to eq(checksum)
    end
  end
end
