describe OddsFeed::Radar::Entities::CompetitorLoader do
  subject { described_class.new(external_id: external_id) }

  let(:payload) do
    XmlParser.parse(file_fixture('radar_competitor_profile.xml').read)
  end
  let(:competitor_payload) { payload.dig('competitor_profile', 'competitor') }
  let(:external_id)        { competitor_payload['id'] }

  let(:cache_settings) do
    {
      cache: { expires_in: OddsFeed::Radar::Client::DEFAULT_CACHE_TERM }
    }
  end

  let(:name) do
    competitor_payload['name']
      .split(described_class::NAME_SEPARATOR)
      .reverse
      .join(' ')
  end

  before do
    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:competitor_profile)
      .with(external_id, cache_settings)
      .and_return(payload)

    allow(Rails.cache).to receive(:read)
  end

  context 'take cached value' do
    let(:name) { Faker::WorldOfWarcraft.hero }

    before { expect(Rails.cache).to receive(:read).and_return(name) }

    it { expect(subject.call).to eq(name) }

    it do
      expect(subject).not_to receive(:radar_entity_name)
      subject.call
    end
  end

  context 'load new player from Radar API' do
    before { expect(Rails.cache).to receive(:write) }

    let(:subject_with_name) { described_class.new(external_id: external_id) }

    it { expect(subject_with_name.call).to eq(name) }

    it do
      expect(
        subject_with_name
      ).to receive(:radar_entity_name).once.and_call_original
      subject_with_name.call
    end
  end
end
