describe Address do
  subject { build(:address) }

  let(:state) { subject.state }
  let(:country) { subject.country }
  let(:country_details) do
    ISO3166::Country.find_country_by_name(subject.country)
  end

  it { is_expected.to belong_to(:customer) }

  describe '#to_s' do
    let(:street_address) { subject.street_address }
    let(:zip_code) { subject.zip_code }

    it 'works' do
      expect(subject.to_s)
        .to eq("#{street_address}, #{zip_code}, #{state}, #{country}")
    end

    context 'without certain fields' do
      before do
        subject.assign_attributes(street_address: nil, state: nil)
      end

      it 'works' do
        expect(subject.to_s).to eq("#{zip_code}, #{country}")
      end
    end
  end

  describe '#country_details' do
    it 'works' do
      expect(subject.country_details).to eq(country_details)
    end
  end

  describe '#country_code' do
    it 'works' do
      expect(subject.country_code).to eq(country_details.alpha2)
    end
  end

  describe '#state_code' do
    let(:canada) { ISO3166::Country.new('CA') }
    let(:state_data) { canada.subdivision_names_with_codes.sample }

    before do
      subject.assign_attributes(country: canada.to_s, state: state_data.first)
    end

    it 'works' do
      expect(subject.state_code).to eq(state_data.last)
    end
  end
end
