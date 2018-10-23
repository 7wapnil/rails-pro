describe ::EventDetails::Factory do
  it 'returns adapter instance' do
    expect(described_class.build(create(:event)))
      .to be_a(::EventDetails::Base)
  end
end
