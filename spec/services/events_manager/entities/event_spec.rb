describe EventsManager::Entities::Event do
  subject { described_class.new(event_data) }

  let(:fixture) { file_fixture('radar_event_fixture.xml').read }
  let(:event_data) do
    ::XmlParser.parse(fixture)
  end

  it 'return external id' do
    expect(subject.id).to eq('sr:match:8696826')
  end

  it 'returns event name' do
    expect(subject.name).to eq('IK Oddevold VS Tvaakers IF')
  end

  it 'returns traded live flag' do
    expect(subject).not_to be_traded_live
  end

  context 'empty scopes' do
    let(:fixture) do
      file_fixture('radar_event_fixture_no_scopes.xml').read
    end

    it 'returns nil on empty season' do
      expect(subject.season).to be_nil
    end

    it 'returns nil on empty category' do
      expect(subject.category).to be_nil
    end
  end

  context 'replay model OFF' do
    before do
      allow(ENV).to receive(:[])
        .with('RADAR_MQ_IS_REPLAY')
        .and_return('false')
    end

    it 'returns start time from response' do
      expect(subject.start_at).to eq('2016-10-31T18:00:00+00:00')
    end
  end

  context 'replay mode ON' do
    before do
      allow(ENV).to receive(:[])
        .with('RADAR_MQ_IS_REPLAY')
        .and_return('true')
    end

    it 'returns start time in the future' do
      expect(subject.start_at).to be > Time.zone.now
    end
  end
end
