describe OddsFeed::Radar::Entities::CompetitorLoader do
  subject { described_class.new(external_id: external_id) }

  let(:payload) do
    XmlParser.parse(file_fixture('radar_competitor_profile.xml').read)
  end
  let(:competitor_payload) { payload.dig('competitor_profile', 'competitor') }
  let(:external_id)        { competitor_payload['id'] }
  let(:name) do
    competitor_payload['name']
      .split(described_class::NAME_SEPARATOR)
      .reverse
      .join(' ')
  end

  before do
    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:competitor_profile).with(external_id).and_return(payload)

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