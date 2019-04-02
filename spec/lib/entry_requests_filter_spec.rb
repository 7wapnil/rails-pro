describe EntryRequestsFilter do
  let(:filter) { described_class.new(source: EntryRequest) }

  describe '#search' do
    it 'returns ransack Search object' do
      expect(filter.search).to be_instance_of(Ransack::Search)
    end
  end

  describe '#requests' do
    it 'returns paged results' do
      expect(filter.requests).to respond_to(:total_pages)
    end
  end
end
