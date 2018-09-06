describe OddsFeed::Radar::EventAdapter do
  let(:event_id) { 'sr:match:8696826' }
  let(:payload) do
    XmlParser.parse(file_fixture('radar_event_fixture.xml').read)
  end
  let(:result) { subject.result }
  let(:title) { create(:title, external_id: 'sr:sport:1', name: 'Soccer') }

  subject { OddsFeed::Radar::EventAdapter.new(payload) }

  it 'returns filled event' do
    expected_payload = {
      'competitors': payload['fixtures_fixture']['fixture']['competitors']
    }.stringify_keys

    expect(result).to be_a(Event)
    expect(result.external_id).to eq('sr:match:8696826')
    expect(result.payload).to eq(expected_payload)
    expect(result.start_at)
      .to eq('2016-10-31T18:00:00+00:00'.to_time)
  end

  it 'returns generated event name' do
    expect(result.name).to eq('IK Oddevold VS Tvaakers IF')
  end

  it 'raises an error if competitors amount is wrong' do
    payload['fixtures_fixture']['fixture']['competitors']['competitor']
      .push('Test competitor')
    expect { result }.to raise_error(NotImplementedError)
  end

  context 'title' do
    it 'creates if not exists in db' do
      expect(result.title).not_to be_nil
      expect(result.title.external_id).to eq('sr:sport:1')
      expect(result.title.name).to eq('Soccer')
    end

    it 'loads if exists in db' do
      existing = create(:title, name: 'Soccer', external_id: 'sr:sport:1')
      expect(result.title.id).to eq(existing.id)
      expect(result.title.external_id).to eq('sr:sport:1')
    end
  end

  context 'tournament' do
    it 'creates if not exists in db' do
      tournament = result.event_scopes.detect(&:tournament?)
      expect(tournament).not_to be_nil
      expect(tournament.external_id).to eq('4301')
      expect(tournament.name).to eq('Division 1, Södra')
    end

    it 'loads if exists in db' do
      existing = create(:event_scope,
                        name: 'Division 1, Södra',
                        external_id: '4301',
                        kind: :tournament,
                        title: title)
      tournament = result.event_scopes.detect(&:tournament?)
      expect(tournament.id).to eq(existing.id)
      expect(tournament.external_id).to eq('4301')
      expect(tournament.name).to eq('Division 1, Södra')
    end
  end

  context 'season' do
    it 'creates if not exists in db' do
      season = result.event_scopes.detect(&:season?)
      expect(season).not_to be_nil
      expect(season.external_id).to eq('sr:season:12346')
      expect(season.name).to eq('Div 1, Sodra 2016')
    end

    it 'loads if exists in db' do
      existing = create(:event_scope,
                        name: 'Div 1, Sodra 2016',
                        external_id: 'sr:season:12346',
                        kind: :season,
                        title: title)
      season = result.event_scopes.detect(&:season?)
      expect(season.id).to eq(existing.id)
      expect(season.external_id).to eq('sr:season:12346')
      expect(season.name).to eq('Div 1, Sodra 2016')
    end
  end

  context 'country' do
    it 'creates if not exists in db' do
      country = result.event_scopes.detect(&:country?)
      expect(country).not_to be_nil
      expect(country.external_id).to eq('sr:category:9')
      expect(country.name).to eq('Sweden')
    end

    it 'loads if exists in db' do
      existing = create(:event_scope,
                        name: 'Sweden',
                        external_id: 'sr:category:9',
                        kind: :country,
                        title: title)
      country = result.event_scopes.detect(&:country?)
      expect(country.id).to eq(existing.id)
      expect(country.external_id).to eq('sr:category:9')
      expect(country.name).to eq('Sweden')
    end
  end

  context 'invalid data' do
    it 'raises error if title data is invalid' do
      payload['fixtures_fixture']['fixture']['tournament']['sport'] = {}
      expect { result }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'raises error if tournament data is invalid' do
      payload['fixtures_fixture']['fixture']['tournament_round'] = {}
      expect { result }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'raises error if season data is invalid' do
      payload['fixtures_fixture']['fixture']['season'] = {}
      expect { result }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'raises error if country data is invalid' do
      payload['fixtures_fixture']['fixture']['tournament']['category'] = {}
      expect { result }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
