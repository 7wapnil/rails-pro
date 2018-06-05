describe EntryRequest, type: :model do
  it { is_expected.to define_enum_for :status }
  it { should validate_presence_of(:payload) }

  let!(:request) do
    create(
      :entry_request,
      payload: {
        customer_id: create(:customer).id,
        kind: :deposit,
        amount: 29.99,
        currency: :euro
      }
    )
  end

  it 'returns payload as instance of EntryRequestPayload' do
    expect(request.payload).to be_an EntryRequestPayload
  end

  it 'calls payload validation on request validate' do
    expect_any_instance_of(EntryRequestPayloadValidator)
      .to receive(:validate_each)

    request.validate
  end
end
