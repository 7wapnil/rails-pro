# frozen_string_literal: true

describe ::Payments::SafeCharge::Deposits::RequestHandler do
  subject { described_class.call(transaction, **extra_query_params) }

  let(:transaction) do
    ::Payments::Transactions::Deposit.new(
      id: entry_request.id,
      method: Payments::Methods::CREDIT_CARD,
      customer: entry_request.customer,
      currency_code: entry_request.currency.code,
      amount: entry_request.amount
    )
  end

  let(:customer) { create(:customer, :with_address) }
  let(:entry_request) { create(:entry_request, customer: customer) }
  let!(:balance_entry_request) do
    create(:balance_entry_request, entry_request: entry_request)
  end
  let(:extra_query_params) { {} }
  let(:amount) { entry_request.amount }

  let(:payment_url) { Faker::Internet.url }
  let(:merchant_id) { Faker::Bank.account_number }
  let(:merchant_site_id) { Faker::Vehicle.vin }
  let(:secret_key) { Faker::Vehicle.vin }
  let(:brand_name) { Faker::Restaurant.name }
  let(:web_protocol) { 'http' }

  let(:result_uri) { URI.parse(subject) }
  let(:result_query) do
    OpenStruct.new(
      CGI.parse(result_uri.query).transform_values(&:last)
    )
  end

  before do
    allow(::Payments::SafeCharge::PaymentUrlValidator)
      .to receive(:call)
      .and_return(true)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV)
      .to receive(:[])
      .with('APP_HOST')
      .and_return(payment_url)

    allow(ENV)
      .to receive(:[])
      .with('SAFECHARGE_HOSTED_PAYMENTS_URL')
      .and_return(payment_url)

    allow(ENV)
      .to receive(:[])
      .with('SAFECHARGE_MERCHANT_ID')
      .and_return(merchant_id)

    allow(ENV)
      .to receive(:[])
      .with('SAFECHARGE_MERCHANT_SITE_ID')
      .and_return(merchant_site_id)

    allow(ENV)
      .to receive(:[])
      .with('SAFECHARGE_SECRET_KEY')
      .and_return(secret_key)

    allow(ENV)
      .to receive(:[])
      .with('BRAND_NAME')
      .and_return(brand_name)

    allow(ENV)
      .to receive(:fetch)
      .with('WEB_PROTOCOL', any_args)
      .and_return(web_protocol)
  end

  it 'takes payment uri from ENV' do
    expect(result_uri.to_s.split('?').first).to eq(payment_url)
  end

  it 'is configured for 4.0.0 version' do
    expect(result_query.version).to eq('4.0.0')
  end

  it 'appends SafeCharge keys' do
    expect(result_query)
      .to have_attributes(
        merchant_id: merchant_id,
        merchant_site_id: merchant_site_id
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
      expect(result_query)
        .to have_attributes(
          encoding: Encoding::UTF_8.to_s,
          time_stamp: time_stamp,
          userid: customer.id.to_s,
          productId: entry_request.id.to_s,
          currency: currency.code,
          user_token_id: customer.id.to_s,
          item_name_1: item_name,
          item_number_1: entry_request.id.to_s,
          item_amount_1: amount.to_s,
          item_quantity_1: described_class::ITEM_QUANTITY.to_s,
          total_amount: amount.to_s
        )
    end
  end

  context 'customer info' do
    let(:address) { customer.address }
    let(:date_of_birth) do
      customer.date_of_birth.strftime(described_class::DATE_OF_BIRTH_FORMAT)
    end

    it 'are appended' do
      expect(result_query)
        .to have_attributes(
          first_name: customer.first_name,
          last_name: customer.last_name,
          email: customer.email,
          phone1: customer.phone,
          dateOfBirth: date_of_birth,
          address1: address.street_address,
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
        expect(result_query.state).to be_nil
      end
    end
  end

  context 'additional parameters' do
    it 'are appended' do
      expect(result_query.isNative).to eq('1')
    end
  end

  context 'url parameters', routes: true do
    let(:webhook_url) do
      webhooks_safe_charge_payment_url(
        host: payment_url,
        protocol: web_protocol,
        request_id: transaction.id
      )
    end
    let(:cancellation_signature) do
      OpenSSL::HMAC.hexdigest('sha256', secret_key, transaction.id.to_s)
    end
    let(:cancellation_redirection_url) do
      webhooks_safe_charge_payment_cancel_url(
        host: payment_url,
        protocol: web_protocol,
        request_id: transaction.id,
        signature: cancellation_signature
      )
    end

    it 'are appended' do
      expect(result_query)
        .to have_attributes(
          success_url: webhook_url,
          error_url: webhook_url,
          pending_url: webhook_url,
          back_url: cancellation_redirection_url,
          notify_url: webhook_url
        )
    end
  end

  context 'checksum' do
    let(:squash_parameters) { result_query.to_h.except(:checksum).values.join }
    let(:checksum) do
      Digest::SHA256.hexdigest("#{secret_key}#{squash_parameters}")
    end

    it 'is appended' do
      expect(result_query.checksum).to eq(checksum)
    end
  end

  context 'accepts extra query' do
    context 'common params' do
      let(:encoding) { Encoding.name_list.sample }
      let(:item_name_1) { Faker::WorldOfWarcraft.quote }
      let(:is_native) do
        ::Payments::SafeCharge::PaymentUrlValidator::BOOLEAN_OPTIONS.sample.to_s
      end

      let(:extra_query_params) do
        {
          encoding: encoding,
          item_name_1: item_name_1,
          isNative: is_native
        }
      end

      it 'and works' do
        expect(result_query)
          .to have_attributes(
            encoding: encoding,
            item_name_1: item_name_1,
            isNative: is_native
          )
      end
    end

    context 'time_stamp param is passed as DateTime' do
      let(:time_stamp) { rand(7).days.ago }
      let(:extra_query_params) { { time_stamp: time_stamp } }

      let(:formatted_time_stamp) do
        time_stamp.strftime(described_class::TIMESTAMP_FORMAT)
      end

      it 'and works' do
        expect(result_query.time_stamp).to eq(formatted_time_stamp)
      end
    end

    context 'time_stamp param is passed as Date' do
      let(:time_stamp) { rand(7).days.ago.to_date }
      let(:extra_query_params) { { time_stamp: time_stamp } }

      let(:formatted_time_stamp) do
        time_stamp.strftime(described_class::TIMESTAMP_FORMAT)
      end

      it 'and works' do
        expect(result_query.time_stamp).to eq(formatted_time_stamp)
      end
    end

    context 'time_stamp param is passed as String' do
      let(:time_stamp) { rand(7).days.ago }
      let(:formatted_time_stamp) do
        time_stamp.strftime(described_class::TIMESTAMP_FORMAT)
      end

      let(:extra_query_params) { { time_stamp: formatted_time_stamp } }

      it 'and works' do
        expect(result_query.time_stamp).to eq(formatted_time_stamp)
      end
    end
  end

  context 'validation' do
    let(:checksum) { Faker::Crypto.sha256 }

    before do
      allow(Digest::SHA256).to receive(:hexdigest).and_return(checksum)
    end

    it 'is called with checksum' do
      expect(::Payments::SafeCharge::PaymentUrlValidator)
        .to receive(:call)
        .with(url: payment_url, query_hash: hash_including(checksum: checksum))

      subject
    end

    context 'on error' do
      before do
        allow(::Payments::SafeCharge::PaymentUrlValidator)
          .to receive(:call)
          .and_raise(SafeCharge::InvalidPaymentUrlError)
      end

      it "doesn't proceed" do
        expect { subject }.to raise_error(::SafeCharge::InvalidPaymentUrlError)
      end
    end
  end
end
