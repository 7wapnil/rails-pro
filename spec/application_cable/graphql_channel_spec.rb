# Add tests for auth-require subscription endpoints when
# they will be added
#
# To stub connection use `stub_connection`
# To stub with customer authenticated us `stub_connection customer: customer`
#
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
