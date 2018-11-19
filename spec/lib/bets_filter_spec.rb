describe BetsFilter do
  let!(:country) do
    create(:event_scope, kind: :country, name: Faker::Address.country)
  end

  let!(:tournament) do
    create(:event_scope, kind: :tournament, name: Faker::Esport.league)
  end

  let!(:sport) { create(:title, name: Faker::Esport.game) }

  let(:filter) { described_class.new(Bet, {}) }

  it 'returns sports' do
    expect(filter.sports).to include(sport.name)
  end

  it 'returns countries' do
    expect(filter.countries).to match_array([country.name])
  end

  it 'returns tournaments' do
    expect(filter.tournaments).to match_array([tournament.name])
  end

  it 'returns ransack Search object' do
    expect(filter.search).to be_instance_of(Ransack::Search)
  end
end
