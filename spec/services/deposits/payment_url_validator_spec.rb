describe Deposits::PaymentUrlValidator do
  subject do
    described_class.call(url: payment_url, query_hash: query_hash)
  end

  let(:entry_request) { build_stubbed(:entry_request) }
  let(:currency) { build_stubbed(:currency, :allowed_by_safe_charge) }
  let(:customer) { build_stubbed(:customer) }
  let(:address) { build_stubbed(:address, :with_state) }

  let(:payment_url) { Faker::Internet.url }
  let(:merchant_id) { Faker::Bank.account_number }
  let(:merchant_site_id) { Faker::Vehicle.vin }
  let(:urls) { Array.new(5) { Faker::Internet.url } }
  let(:checksum) { Faker::Crypto.sha256 }
  let(:time_stamp) do
    Time.zone.now.strftime(Deposits::GetPaymentPageUrl::TIME_STAMP_FORMAT)
  end

  let(:date_of_birth) do
    customer
      .date_of_birth
      .strftime(Deposits::GetPaymentPageUrl::DATE_OF_BIRTH_FORMAT)
  end

  let(:query_params) do
    {
      merchant_id: merchant_id,
      merchant_site_id: merchant_site_id,
      version: Deposits::GetPaymentPageUrl::API_VERSION,
      encoding: Encoding::UTF_8.to_s,
      time_stamp: time_stamp,
      currency: currency.code,
      userId: customer.id,
      merchant_unique_id: entry_request.id,
      user_token_id: customer.id,
      item_name_1: Faker::WorldOfWarcraft.quote,
      item_number_1: entry_request.id,
      item_amount_1: entry_request.amount,
      item_quantity_1: Deposits::GetPaymentPageUrl::ITEM_QUANTITY,
      total_amount: entry_request.amount,
      first_name: customer.first_name,
      last_name: customer.last_name,
      email: customer.email,
      phone1: customer.phone,
      dateOfBirth: date_of_birth,
      address1: address.street_address,
      city: address.city,
      country: address.country_code,
      state: address.state_code,
      zip: address.zip_code,
      isNative: 1,
      success_url: urls.first,
      error_url: urls.second,
      pending_url: urls.third,
      back_url: urls.fourth,
      notify_url: urls.fifth,
      checksum: checksum
    }
  end
  let(:query_hash) { query_params }

  let(:secret_key) { Faker::Vehicle.vin }

  before do
    allow(Digest::SHA256).to receive(:hexdigest).and_return(checksum)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV)
      .to receive(:[])
      .with('SAFECHARGE_SECRET_KEY')
      .and_return(secret_key)
  end

  it 'passes validation' do
    expect(subject).to be_truthy
  end

  context 'on missing payment url' do
    let(:payment_url) { '' }

    it 'receives failure' do
      expect { subject }
        .to raise_error(
          SafeCharge::InvalidPaymentUrlError,
          'Payment url is not provided.'
        )
    end
  end

  context 'on missing mandatory fields' do
    let(:control_count) { rand(1..described_class::MANDATORY_FIELDS.length) }
    let(:excluded_fields) do
      described_class::MANDATORY_FIELDS
        .sample(control_count)
        .sort_by { |field| described_class::MANDATORY_FIELDS.index(field) }
    end

    let(:query_hash) { query_params.except(*excluded_fields) }

    it 'receives failure' do
      expect { subject }
        .to raise_error(
          SafeCharge::InvalidPaymentUrlError,
          "Fields are required: #{excluded_fields.join(', ')}."
        )
    end
  end

  context 'on invalid encoding' do
    let(:value) { 'Kek' }
    let(:query_hash) { query_params.merge(encoding: value) }

    it 'receives failure' do
      expect { subject }
        .to raise_error(
          SafeCharge::InvalidPaymentUrlError,
          "`#{value}` is invalid encoding type."
        )
    end
  end

  context 'on invalid currency' do
    let(:value) { 'BTC' }
    let(:query_hash) { query_params.merge(currency: value) }

    it 'receives failure' do
      expect { subject }
        .to raise_error(
          SafeCharge::InvalidPaymentUrlError,
          "`#{value}` currency is not supported."
        )
    end
  end

  context 'checks amount' do
    context 'and when total_amount is zero' do
      let(:query_hash) { query_params.merge(total_amount: 0) }

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'Amount has to be positive.'
          )
      end
    end

    context 'and when total_amount is negative' do
      let(:query_hash) do
        query_params.merge(total_amount: Faker::Number.negative)
      end

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'Amount has to be positive.'
          )
      end
    end

    context 'and when item_amount_1 is zero' do
      let(:query_hash) { query_params.merge(item_amount_1: 0) }

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'Amount has to be positive.'
          )
      end
    end

    context 'and when item_amount_1 is negative' do
      let(:query_hash) do
        query_params.merge(item_amount_1: Faker::Number.negative)
      end

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'Amount has to be positive.'
          )
      end
    end
  end

  context 'checks time_stamp' do
    context 'when in invalid format' do
      let(:query_hash) { query_params.merge(time_stamp: Time.zone.now.to_s) }

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'time_stamp has wrong format.'
          )
      end
    end

    context 'when random text' do
      let(:query_hash) { query_params.merge(time_stamp: Faker::Lorem.word) }

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'time_stamp has wrong format.'
          )
      end
    end
  end

  context 'checks dateOfBirth' do
    context 'when is empty' do
      let(:query_hash) { query_params.merge(dateOfBirth: nil) }

      it 'passes validation' do
        expect(subject).to be_truthy
      end
    end

    context 'when in invalid format' do
      let(:query_hash) do
        query_params.merge(dateOfBirth: Time.zone.now.strftime('%d\%M\%Y'))
      end

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'dateOfBirth has wrong format.'
          )
      end
    end

    context 'when random text' do
      let(:query_hash) { query_params.merge(dateOfBirth: Faker::Lorem.word) }

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'dateOfBirth has wrong format.'
          )
      end
    end
  end

  context 'on invalid boolean fields' do
    let(:query_hash) { query_params.merge(isNative: true) }

    it 'receives failure' do
      expect { subject }
        .to raise_error(
          SafeCharge::InvalidPaymentUrlError,
          'Fields have to be 0 or 1: isNative.'
        )
    end
  end

  context 'checks address fields' do
    context 'on invalid country' do
      let(:query_hash) { query_params.merge(country: 'ZZZ') }

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'Provided country is not supported.'
          )
      end
    end

    context 'on empty country' do
      let(:query_hash) { query_params.merge(country: nil) }

      it 'passes validation' do
        expect(subject).to be_truthy
      end
    end

    context 'on invalid state' do
      let(:query_hash) { query_params.merge(state: 'ZZZ') }

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'Provided state is not supported.'
          )
      end
    end

    context 'on empty state for country with states' do
      let(:query_hash) { query_params.merge(state: nil) }

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'Provided state is not supported.'
          )
      end
    end

    context 'on any state for country without states' do
      let(:query_hash) { query_params.merge(state: 'VI', country: 'UA') }

      it 'receives failure' do
        expect { subject }
          .to raise_error(
            SafeCharge::InvalidPaymentUrlError,
            'Provided state is not supported.'
          )
      end
    end

    context 'on empty state for country without states' do
      let(:query_hash) { query_params.merge(state: nil, country: 'UA') }

      it 'passes validation' do
        expect(subject).to be_truthy
      end
    end
  end

  context 'on invalid checksum' do
    let(:query_hash) { query_params.merge(checksum: 'wrong-checksum') }

    it 'receives failure' do
      expect { subject }
        .to raise_error(
          SafeCharge::InvalidPaymentUrlError,
          'Checksum is corrupted.'
        )
    end
  end
end
