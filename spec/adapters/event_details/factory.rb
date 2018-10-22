describe ::EventDetails::Factory do
  it 'returns adapter instance' do
    allow(described_class).to receive(:provider).and_return(:radar)
    expect(described_class.build(create(:event)))
      .to be_a(::EventDetails::Base)
  end

  it 'raises error on unknown provider' do
    allow(described_class).to receive(:provider).and_return(:unknown)
    expect { described_class.build(create(:event)) }
      .to raise_error(NotImplementedError)
  end
end
