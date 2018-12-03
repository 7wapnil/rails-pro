describe OddsFeed::Radar::Entities::VenueLoader do
  subject { described_class.new(external_id: external_id) }

  let(:payload) do
    XmlParser.parse(file_fixture('radar_venue_summary.xml').read)
  end
  let(:venue_payload) { payload.dig('venue_summary', 'venue') }
  let(:external_id)   { venue_payload['id'] }
  let(:name)          { venue_payload['name'] }

  before do
    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:venue_summary).with(external_id).and_return(payload)

    allow_any_instance_of(Redis).to receive(:hget)
  end

  context 'take cached value' do
    let(:name) { Faker::WorldOfWarcraft.hero }

    before { expect_any_instance_of(Redis).to receive(:hget).and_return(name) }

    it { expect(subject.call).to eq(name) }

    it do
      expect(subject).not_to receive(:radar_entity_name)
      subject.call
    end

    it do
      expect_any_instance_of(Redis).to receive(:disconnect!).and_call_original
      subject.call
    end
  end

  context 'load new player from Radar API' do
    before { expect_any_instance_of(Redis).to receive(:hset) }

    it { expect(subject.call).to eq(name) }

    it do
      expect(subject)
        .to receive(:radar_entity_name).at_least(:once).and_call_original
      subject.call
    end
  end
end
