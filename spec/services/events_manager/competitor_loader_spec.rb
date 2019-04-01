describe EventsManager::CompetitorLoader do
  subject { described_class.new(external_id) }

  let(:external_id) { 'sr:competitor:1860' }
  let(:competitor_response) do
    fixture = file_fixture('competitors/competitor_1860.xml').read
    ::XmlParser.parse(fixture)
  end

  before do
    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:competitor_profile)
      .and_return(competitor_response)
  end

  context 'attributes building' do
    it 'stores external id from response' do
      competitor = subject.call
      expect(competitor.external_id).to eq(external_id)
    end

    it 'stores name id from response' do
      competitor = subject.call
      expect(competitor.name).to eq('IK Oddevold')
    end
  end

  context 'players' do
    it 'loads players to database' do
      competitor = subject.call
      expect(competitor.players.count).to eq(3)
    end
  end
end
