describe EntryRequest do
  it { should define_enum_for :status }
  it { should validate_presence_of(:payload) }

  let(:request) { build(:entry_request) }

  it 'returns payload as instance of EntryRequestPayload' do
    expect(request.payload).to be_an EntryRequestPayload
  end

  it 'calls payload validation on request validate' do
    expect_any_instance_of(ChildValidator)
      .to receive(:validate_each)

    request.validate
  end
end
