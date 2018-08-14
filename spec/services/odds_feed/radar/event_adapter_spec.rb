describe OddsFeed::Radar::EventAdapter do
  let(:event_id) { 'sr:match:8696826' }
  let(:payload) do
    Hash.from_xml(file_fixture('radar_event_fixture.xml').read)
  end
  let(:adapter) { OddsFeed::Radar::EventAdapter.new(payload) }
  let(:result) { adapter.result }

  it 'returns filled event' do
    expected_payload = {
      'competitors': payload['fixtures_fixture']['fixture']['competitors']
    }.stringify_keys

    expect(result).to be_a(Event)
    expect(result.external_id).to eq('sr:match:8696826')
    expect(result.payload).to eq(expected_payload)
  end

  it 'returns filled event title' do
    expect(result.title).not_to be_nil
    expect(result.title.external_id).to eq('sr:sport:1')
    expect(result.title.name).to eq('Soccer')
  end

  it 'returns filled tournament scope' do
    tournament = result.event_scopes[0]
    expect(tournament).not_to be_nil
    expect(tournament.external_id).to eq('4301')
    expect(tournament.name).to eq('Division 1, Södra')
  end

  it 'returns filled season scope' do
    season = result.event_scopes[1]
    expect(season).not_to be_nil
    expect(season.external_id).to eq('sr:season:12346')
    expect(season.name).to eq('Div 1, Sodra 2016')
  end

  it 'returns filled country scope' do
    country = result.event_scopes[2]
    expect(country).not_to be_nil
    expect(country.external_id).to eq('sr:category:9')
    expect(country.name).to eq('Sweden')
  end

  it 'returns generated event name' do
    expect(result.name).to eq('IK Oddevold VS Tvaakers IF')
  end

  it 'raises an error if competitors amount is wrong' do
    payload['fixtures_fixture']['fixture']['competitors']['competitor']
      .push('Test competitor')
    expect { result }.to raise_error(NotImplementedError)
  end
end
