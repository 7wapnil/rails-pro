describe BetsFilter do
  let(:usa) { 'USA' }
  let(:xbet) { 'X-BET' }
  let(:fifa) { 'FIFA' }

  let(:filter) { described_class.new(Bet, {}) }
  before do
    create(:event_scope, kind: :country, name: usa)
    create(:event_scope, kind: :tournament, name: xbet)
    create(:title, name: fifa)
  end

  it 'returns sports' do
    expect(filter.sports).to include(fifa)
  end

  it 'returns countries' do
    expect(filter.countries).to match_array([usa])
  end

  it 'returns tournaments' do
    expect(filter.tournaments).to match_array([xbet])
  end

  it 'returns ransack Search object' do
    expect(filter.search).to be_instance_of(Ransack::Search)
  end
end
