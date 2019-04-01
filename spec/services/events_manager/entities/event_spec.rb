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

  context 'replay mode ON' do
    before do
      ENV['RADAR_MQ_IS_REPLAY'] = 'true'
    end

    it 'returns start time in the future' do
      expect(subject.start_at).to be > DateTime.now
    end
  end

  context 'replay mode OFF' do
    before do
      ENV['RADAR_MQ_IS_REPLAY'] = 'false'
    end

    it 'returns start time from response' do
      expect(subject.start_at).to eq('2016-10-31T18:00:00+00:00')
    end
  end
end
