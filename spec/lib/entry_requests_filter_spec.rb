describe EntryRequestsFilter do
  let(:filter) { described_class.new(source: EntryRequest) }

  it 'returns ransack Search object' do
    expect(filter.search).to be_instance_of(Ransack::Search)
  end
end
