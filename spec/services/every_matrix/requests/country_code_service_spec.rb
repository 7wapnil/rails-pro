# frozen_string_literal: true

describe EveryMatrix::Requests::CountryCodeService do
  subject { described_class.call(params) }

  let(:params) { { customer: customer } }
  let(:customer) { create(:customer, :with_address) }

  context 'develop setup' do
    before do
      allow(Rails.env).to receive(:production?).and_return(false)
    end

    context 'when ip lookup finds country' do
      before do
        Geocoder.configure(lookup: :test, ip_lookup: :test)
        Geocoder::Lookup::Test.set_default_stub([{ 'country' => 'UA' }])
      end

      it 'returns ip-based country' do
        expect(subject).to eq('UKR')
      end
    end

    context 'when ip lookup fails to find country' do
      let(:expected_country) do
        ISO3166::Country.find_country_by_name(customer.address.country).alpha3
      end
      let(:message) do
        {
          message: 'Country lookup failed',
          customer_id: customer.id,
          customer_ip: customer.current_sign_in_ip&.to_string,
          searched_country: wrong_country_name
        }
      end
      let(:wrong_country_name) { Faker::GameOfThrones.character }

      before do
        Geocoder.configure(lookup: :test, ip_lookup: :test)
        Geocoder::Lookup::Test.set_default_stub(
          [{ 'country' => wrong_country_name }]
        )
      end

      it 'returns profile-based country' do
        expect(subject).to eq(expected_country)
      end

      it 'logs warning' do
        expect(Rails.logger).to receive(:warn).with(message)

        subject
      end
    end
  end

  context 'prod setup' do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV)
        .to receive(:[]).with('WERCKER_DEPLOYTARGET_NAME').and_return('store')
    end

    context 'when ip lookup finds country' do
      before do
        Geocoder.configure(lookup: :test, ip_lookup: :test)
        Geocoder::Lookup::Test.set_default_stub(
          [{ 'country' => { 'iso_code' => 'UA' } }]
        )
      end

      it 'returns ip-based country' do
        expect(subject).to eq('UKR')
      end
    end

    context 'when ip lookup fails to find country' do
      let(:expected_country) do
        ISO3166::Country.find_country_by_name(customer.address.country).alpha3
      end
      let(:message) do
        {
          message: 'Country lookup failed',
          customer_id: customer.id,
          customer_ip: customer.current_sign_in_ip&.to_string,
          searched_country: wrong_country_name
        }
      end
      let(:wrong_country_name) { Faker::GameOfThrones.character }

      before do
        Geocoder.configure(lookup: :test, ip_lookup: :test)
        Geocoder::Lookup::Test.set_default_stub(
          [{ 'country' => { 'iso_code' => wrong_country_name } }]
        )
      end

      it 'returns profile-based country' do
        expect(subject).to eq(expected_country)
      end

      it 'logs warning' do
        expect(Rails.logger).to receive(:warn).with(message)

        subject
      end
    end
  end
end
