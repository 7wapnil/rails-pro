describe EventsManager::EventLoader do
  subject { described_class.new(external_id) }

  let(:external_id) { 'sr:match:8696826' }
  let(:event_response) do
    ::XmlParser.parse(file_fixture('radar_event_fixture.xml').read)
  end

  before do
    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:event_raw)
      .and_return(event_response)

    allow_any_instance_of(EventsManager::CompetitorLoader)
      .to receive(:call)
      .and_return(create(:competitor, external_id: 'sr:competitor:1'))
  end

  context 'attributes building' do
    it 'raises error if event exists in database' do
      create(:event, external_id: external_id)
      subject.options = { check_existence: true }
      expect { subject.call }.to raise_error(StandardError)
    end

    it 'builds attributes from response' do
      event = subject.call
      expect(event.external_id).to eq(external_id)
    end
  end

  context 'title' do
    it 'creates title and associates with event' do
      event = subject.call
      expect(event.title.external_id).to eq('sr:sport:1')
    end

    it 'loads title from db and associates with event' do
      title = create(:title, external_id: 'sr:sport:1')
      event = subject.call
      expect(event.title.id).to eq(title.id)
    end
  end

  context 'competitors' do
    it 'creates competitors and associates with event' do
      event = subject.call
      expect(event.competitors.count).to eq(1)
    end
  end

  context 'scopes' do
    it 'creates competitors and associates with event' do
      event = subject.call
      expect(event.event_scopes.count).to eq(3)
    end
  end

  context 'duplicated' do
    let(:event) { create(:event, external_id: external_id) }

    before do
      event.event_scopes << create(:event_scope,
                                   kind: EventScope::CATEGORY,
                                   external_id: 'sr:category:9')
      event.event_scopes << create(:event_scope,
                                   kind: EventScope::TOURNAMENT,
                                   external_id: 'sr:tournament:68')
      event.event_scopes << create(:event_scope,
                                   kind: EventScope::SEASON,
                                   external_id: 'sr:season:12346')

      event.competitors << create(:competitor,
                                  external_id: 'sr:competitor:1860')
      event.competitors << create(:competitor,
                                  external_id: 'sr:competitor:22356')
    end

    it 'not duplicates scopes associations' do
      expect(subject.call.event_scopes.count).to eq(3)
    end

    it 'not duplicates competitors associations' do
      expect(subject.call.event_competitors.count).to eq(3)
    end
  end
end
