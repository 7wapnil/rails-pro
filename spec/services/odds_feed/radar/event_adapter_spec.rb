describe OddsFeed::Radar::EventAdapter do
  let(:event_id) { 'sr:match:8696826' }
  let(:payload) do
    XmlParser.parse(
      file_fixture('radar_event_fixture.xml').read
    )['fixtures_fixture']['fixture']
  end
  let(:result) { subject.result }
  let(:title) { create(:title, external_id: 'sr:sport:1', name: 'Soccer') }

  subject { described_class.new(payload) }

  let(:tournament) do
    create(:event_scope,
           name: 'Div 1 Sodra',
           external_id: 'sr:tournament:68',
           kind: :tournament,
           title: title)
  end

  let(:season) do
    create(:event_scope,
           name: 'Div 1, Sodra 2016',
           external_id: 'sr:season:12346',
           kind: :season,
           title: title)
  end

  let(:country) do
    create(:event_scope,
           name: 'Sweden',
           external_id: 'sr:category:9',
           kind: :country,
           title: title)
  end

  before do
    tournament
    season
    country
  end

  it 'returns filled event' do
    expected_payload = {
      'competitors': payload['competitors']
    }.stringify_keys

    expect(result).to be_a(Event)
    expect(result.external_id).to eq('sr:match:8696826')
    expect(result.payload).to eq(expected_payload)
    expect(result.start_at)
      .to eq('2016-10-31T18:00:00+00:00'.to_time)
  end

  it 'creates event_archive record at MongoDB' do
    expect(result).to be_a(Event)
    expect(ArchivedEvent.count).to eq(1)
    archived_event = ArchivedEvent.first
    expect(archived_event.external_id).to eq(result.external_id)
    expect(archived_event.scopes.count).to eq(result.event_scopes.size)
  end

  it 'returns generated event name' do
    expect(result.name).to eq('IK Oddevold VS Tvaakers IF')
  end

  it 'raises an error if competitors amount is wrong' do
    payload['competitors']['competitor']
      .push('Test competitor')
    expect { result }.to raise_error(NotImplementedError)
  end

  context 'title' do
    it 'loads if exists in db' do
      expect(result.title.id).to eq(title.id)
      expect(result.title.external_id).to eq('sr:sport:1')
    end

    it 'raises error if title not exists' do
      payload['tournament']['sport']['id'] = 'sr:sport:unknown'
      expect { result }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'tournament' do
    it 'loads existing tournament from db' do
      result_tournament = result.event_scopes.detect(&:tournament?)
      expect(result_tournament.id).to eq(tournament.id)
      expect(result_tournament.external_id).to eq('sr:tournament:68')
      expect(result_tournament.name).to eq('Div 1 Sodra')
    end
  end

  context 'season' do
    it 'loads existing season from db' do
      result_season = result.event_scopes.detect(&:season?)
      expect(result_season.id).to eq(season.id)
      expect(result_season.external_id).to eq('sr:season:12346')
      expect(result_season.name).to eq('Div 1, Sodra 2016')
    end
  end

  context 'country' do
    it 'loads existing country from db' do
      result_country = result.event_scopes.detect(&:country?)
      expect(result_country.id).to eq(country.id)
      expect(result_country.external_id).to eq('sr:category:9')
      expect(result_country.name).to eq('Sweden')
    end
  end

  context 'invalid data' do
    it 'raises error if tournament data is invalid' do
      payload['tournament'] = {}
      expect { result }.to raise_error(OddsFeed::InvalidMessageError)
    end

    it 'raises error if season data is invalid' do
      payload['season'] = {}
      expect { result }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises error if country data is invalid' do
      payload['tournament']['category'] = {}
      expect { result }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
