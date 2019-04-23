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

  it 'stores external id from response' do
    competitor = subject.call
    expect(competitor.external_id).to eq(external_id)
  end

  it 'stores name id from response' do
    competitor = subject.call
    expect(competitor.name).to eq('IK Oddevold')
  end

  it 'loads players to database' do
    competitor = subject.call
    expect(competitor.players.count).to eq(3)
  end

  context 'duplicated' do
    let(:competitor) { create(:competitor, external_id: external_id) }

    before do
      competitor.players << create(:player, external_id: 'sr:player:276289')
      competitor.players << create(:player, external_id: 'sr:player:541260')
      competitor.players << create(:player, external_id: 'sr:player:582508')
    end

    it 'not creates new competitor' do
      expect(subject.call.id).to eq(competitor.id)
    end

    it 'not duplicates players associations' do
      expect(subject.call.players.count).to eq(3)
    end
  end

  context 'invalid identifier' do
    let(:competitor_response) do
      fixture = file_fixture('competitors/unknown_competitor.xml').read
      ::XmlParser.parse(fixture)
    end

    it 'not duplicates players associations' do
      expect(subject.call).to be_nil
    end
  end
end
