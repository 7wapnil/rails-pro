describe EventsManager::Entities::Competitor do
  subject { described_class.new(payload) }

  let(:payload) do
    ::XmlParser.parse(
      file_fixture('competitors/competitor_1860.xml').read
    )
  end

  it 'returns competitor id' do
    expect(subject.id).to eq('sr:competitor:1860')
  end

  it 'returns competitor name' do
    expect(subject.name).to eq('IK Oddevold')
  end

  it 'returns a list of player entities' do
    expect(subject.players.length).to eq(3)
  end

  context 'single player' do
    let(:payload) do
      ::XmlParser.parse(
        file_fixture('competitors/competitor_single_player.xml').read
      )
    end

    it 'returns a list of player entities' do
      expect(subject.players.length).to eq(1)
    end
  end

  context 'no players' do
    let(:payload) do
      ::XmlParser.parse(
        file_fixture('competitors/competitor_with_no_players.xml').read
      )
    end

    it 'returns a list of player entities' do
      expect(subject.players.length).to be_zero
    end
  end
end
