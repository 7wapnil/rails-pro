describe CustomersFilter do
  let(:filter) { described_class.new(source: Customer) }

  it 'returns ransack Search object' do
    expect(filter.search).to be_instance_of(Ransack::Search)
  end
end
