describe EventsManager::CompetitorLoader do
  subject { described_class.new(external_id) }

  let(:external_id) { 'sr:competitor:1860' }
  let(:competitor_response) do
    fixture = file_fixture('competitors/competitor_1860.xml').read
    ::XmlParser.parse(fixture)
  end
  let(:competitor) { subject.call }

  before do
    allow_any_instance_of(::OddsFeed::Radar::Client)
      .to receive(:competitor_profile)
      .and_return(competitor_response)
  end

  it 'stores external id from response' do
    expect(competitor.external_id).to eq(external_id)
  end

  it 'stores name id from response' do
    expect(competitor.name).to eq('IK Oddevold')
  end

  it 'loads players to database' do
    expect(competitor.players.count).to eq(3)
  end

  context 'from simple team' do
    let(:competitor_response) do
      ::XmlParser.parse(
        file_fixture('competitors/simpleteam_competitor.xml').read
      )
    end

    it 'does not have player entities' do
      expect(competitor.players).to be_empty
    end

    it 'loads attributes' do
      expect(competitor).to have_attributes(
        name: 'Lokeren',
        external_id: 'sr:simpleteam:8249060'
      )
    end
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

  context 'invalid player data' do
    let(:competitor_response) do
      fixture = file_fixture('competitors/invalid_players.xml').read
      ::XmlParser.parse(fixture)
    end

    it 'not breaking competitor creation' do
      subject.call
      expect(::Competitor.count).to eq(1)
    end

    it 'skips invalid player' do
      expect(subject.call.players.count).to eq(2)
    end
  end
end
