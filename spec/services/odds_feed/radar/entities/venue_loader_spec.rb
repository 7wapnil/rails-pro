describe OddsFeed::Radar::Entities::VenueLoader do
  subject { described_class.new(external_id: external_id) }

  let(:payload) do
    XmlParser.parse(file_fixture('radar_venue_summary.xml').read)
  end
  let(:venue_payload) { payload.dig('venue_summary', 'venue') }
  let(:external_id)   { venue_payload['id'] }
  let(:name)          { venue_payload['name'] }

  let(:cache_settings) do
    {
      cache: { expires_in: OddsFeed::Radar::Client::DEFAULT_CACHE_TERM }
    }
  end

  before do
    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:venue_summary)
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

    it { expect(subject.call).to eq(name) }

    it do
      expect(subject).to receive(:radar_entity_name).once.and_call_original
      subject.call
    end
  end
end
