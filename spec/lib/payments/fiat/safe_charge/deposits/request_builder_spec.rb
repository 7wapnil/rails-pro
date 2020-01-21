# frozen_string_literal: true

describe ::Payments::Fiat::SafeCharge::Deposits::RequestBuilder do
  include_context 'safecharge_env'

  subject { described_class.call(transaction) }

  let(:payment_method) { Payments::Methods::CREDIT_CARD }
  let(:transaction) do
    ::Payments::Transactions::Deposit.new(
      id: entry_request.id,
      method: payment_method,
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

    it 'appends them' do
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

    context 'when iDebit deposit' do
      let(:payment_method) { ::Payments::Methods::IDEBIT }

      it 'extended userTokenId appended' do
        expect(subject[:userTokenId]).to eq("000#{customer.id}")
      end
    end
  end

  context 'customer info' do
    let(:address) { customer.address }
    let(:address_fields) { subject.fetch(:billingAddress, {}) }

    it 'appends them' do
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

    it 'appends them' do
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

  context 'amount details' do
    let(:min_amount) { described_class::MIN_AMOUNT_LIMIT }
    let(:max_amount) { described_class::MAX_AMOUNT_LIMIT }

    let!(:entry_currency_rule) do
      create(:entry_currency_rule, currency: entry_request.currency,
                                   min_amount: min_amount,
                                   max_amount: max_amount)
    end

    let(:amount_details) { subject.fetch(:amountDetails, {}) }

    it 'appends them' do
      expect(amount_details)
        .to include(
          totalShipping: 0,
          totalHandling: 0,
          totalDiscount: 0,
          totalTax: 0,
          itemOpenAmount1: described_class::OPEN_AMOUNT,
          itemMinAmount1: entry_currency_rule.min_amount,
          itemMaxAmount1: entry_currency_rule.max_amount,
          numberOfItems: described_class::ITEM_QUANTITY
        )
    end

    context 'when there is a big max limit on entry currency rule' do
      let(:max_amount) { described_class::MAX_AMOUNT_LIMIT + 10 }

      it 'appends default max amount limit' do
        expect(amount_details[:itemMaxAmount1])
          .to eq(described_class::MAX_AMOUNT_LIMIT)
      end
    end

    context 'when there is a negative min limit on entry currency rule' do
      let(:min_amount) { -10 }

      it 'appends default min amount limit' do
        expect(amount_details[:itemMinAmount1])
          .to eq(described_class::MIN_AMOUNT_LIMIT)
      end
    end

    context 'when there is no respective entry currency rule' do
      let(:entry_currency_rule) {}

      it 'appends empty limits' do
        expect(amount_details)
          .to include(
            itemMinAmount1: nil,
            itemMaxAmount1: nil
          )
      end
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
