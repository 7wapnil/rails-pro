describe GraphqlChannel, type: :channel do
  let(:customer) { create(:customer) }

  before do
    stub_connection
  end

  it 'connection confirms subscription by default' do
    subscribe
    expect(subscription).to be_confirmed
  end
end
