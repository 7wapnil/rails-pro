describe EntryRequest do
  it { should define_enum_for :status }
  it { should validate_presence_of(:payload) }

  let(:request) { build(:entry_request) }

  it 'returns payload as instance of EntryRequestPayload' do
    expect(request.payload).to be_an EntryRequestPayload
  end

  it 'is valid with invalid payload' do
    request.payload = {
      kind: :invalid,
      currency_code: :none,
      customer_id: 0,
      amount: 'foo'
    }

    expect(request).to be_valid
  end
end
