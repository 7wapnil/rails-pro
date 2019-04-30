describe Deposits::GetPaymentPageUrl do
  subject do
    described_class.call(entry_request: entry_request, **extra_query_params)
  end

  let(:customer) { create(:customer, :with_address) }
  let(:entry_request) { create(:entry_request, customer: customer) }
  let!(:balance_entry_request) do
    create(:balance_entry_request, entry_request: entry_request)
  end
  let(:extra_query_params) { {} }
  let(:amount) { balance_entry_request.amount }

  let(:payment_url) { Faker::Internet.url }
  let(:merchant_id) { Faker::Bank.account_number }
  let(:merchant_site_id) { Faker::Vehicle.vin }
  let(:secret_key) { Faker::Vehicle.vin }
  let(:urls) { Array.new(5) { Faker::Internet.url } }

  let(:result_uri) { URI.parse(subject) }
  let(:result_query) do
    OpenStruct.new(
      CGI.parse(result_uri.query).transform_values(&:last)
    )
  end

  before do
    allow(Deposits::PaymentUrlValidator).to receive(:call).and_return(true)

    allow(ENV).to receive(:[]).and_call_original
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
      .with('SAFECHARGE_DEPOSIT_SUCCESS_URL')
      .and_return(urls.first)

    allow(ENV)
      .to receive(:[])
      .with('SAFECHARGE_DEPOSIT_ERROR_URL')
      .and_return(urls.second)

    allow(ENV)
      .to receive(:[])
      .with('SAFECHARGE_DEPOSIT_PENDING_URL')
      .and_return(urls.third)

    allow(ENV)
      .to receive(:[])
      .with('SAFECHARGE_DEPOSIT_BACK_URL')
      .and_return(urls.fourth)

    allow(ENV)
      .to receive(:[])
      .with('SAFECHARGE_DEPOSIT_NOTIFY_URL')
      .and_return(urls.fifth)
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
      Time.zone.now.strftime(described_class::TIME_STAMP_FORMAT)
    end

    let(:item_name) do
      "Deposit #{balance_entry_request.amount} to your #{currency.code} " \
      'wallet on ArcaneBet.'
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

  context 'url parameters' do
    it 'are appended' do
      expect(result_query)
        .to have_attributes(
          success_url: urls.first,
          error_url: urls.second,
          pending_url: urls.third,
          back_url: urls.fourth,
          notify_url: urls.fifth
        )
    end

    context 'when ENV variables are empty' do
      let(:urls) { Array.new(5) { '' } }

      it 'are not prepended' do
        expect(result_query.to_h.keys)
          .not_to include(
            :success_url,
            :error_url,
            :pending_url,
            :back_url,
            :notify_url
          )
      end
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
        Deposits::PaymentUrlValidator::BOOLEAN_OPTIONS.sample.to_s
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
        time_stamp.strftime(described_class::TIME_STAMP_FORMAT)
      end

      it 'and works' do
        expect(result_query.time_stamp).to eq(formatted_time_stamp)
      end
    end

    context 'time_stamp param is passed as Date' do
      let(:time_stamp) { rand(7).days.ago.to_date }
      let(:extra_query_params) { { time_stamp: time_stamp } }

      let(:formatted_time_stamp) do
        time_stamp.strftime(described_class::TIME_STAMP_FORMAT)
      end

      it 'and works' do
        expect(result_query.time_stamp).to eq(formatted_time_stamp)
      end
    end

    context 'time_stamp param is passed as String' do
      let(:time_stamp) { rand(7).days.ago }
      let(:formatted_time_stamp) do
        time_stamp.strftime(described_class::TIME_STAMP_FORMAT)
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
      expect(Deposits::PaymentUrlValidator)
        .to receive(:call)
        .with(url: payment_url, query_hash: hash_including(checksum: checksum))

      subject
    end

    context 'on error' do
      before do
        allow(Deposits::PaymentUrlValidator)
          .to receive(:call)
          .and_raise(SafeCharge::InvalidPaymentUrlError)
      end

      it "doesn't proceed" do
        expect { subject }.to raise_error(SafeCharge::InvalidPaymentUrlError)
      end
    end
  end
end
