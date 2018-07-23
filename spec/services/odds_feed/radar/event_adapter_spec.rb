describe OddsFeed::Radar::EventAdapter do
  let(:event_id) { 'sr:match:8696826' }
  let(:payload) do
    HTTParty::Parser.call(file_fixture('radar_event_fixture.xml').read, :xml)
  end
  let(:adapter) { OddsFeed::Radar::EventAdapter.new(payload) }
  let(:result) { adapter.result }

  it 'should return filled event' do
    expect(result).to be_a(Event)
    expect(result.external_id).to eq('sr:match:8696826')
  end

  it 'should return filled event title' do
    expect(result.title).not_to be_nil
    expect(result.title.external_id).to eq('sr:sport:1')
    expect(result.title.name).to eq('Soccer')
  end

  it 'should return filled tournament scope' do
    tournament = result.event_scopes[0]
    expect(tournament).not_to be_nil
    expect(tournament.external_id).to eq('4301')
    expect(tournament.name).to eq('Division 1, Södra')
  end

  it 'should return filled season scope' do
    season = result.event_scopes[1]
    expect(season).not_to be_nil
    expect(season.external_id).to eq('sr:season:12346')
    expect(season.name).to eq('Div 1, Sodra 2016')
  end

  it 'should return filled country scope' do
    country = result.event_scopes[2]
    expect(country).not_to be_nil
    expect(country.external_id).to eq('sr:category:9')
    expect(country.name).to eq('Sweden')
  end
end
