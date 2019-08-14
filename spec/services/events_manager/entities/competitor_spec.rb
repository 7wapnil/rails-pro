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

  context 'from simple team' do
    let(:payload) do
      ::XmlParser.parse(
        file_fixture('competitors/simpleteam_competitor.xml').read
      )
    end

    it 'does not have player entities' do
      expect(subject.players).to be_empty
    end

    it 'loads attributes' do
      expect(subject).to have_attributes(
        name: 'Lokeren',
        id: 'sr:simpleteam:8249060'
      )
    end
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
