describe Heartbeat::Service do
  it 'has products hardcoded' do
    expect(Heartbeat::Service::ALLOWED_PRODUCTS).to eq([1 ,3])
  end

  describe '.call' do
    it 'has correct signature' do
      expect(subject)
        .to respond_to(:call)
        .with_keywords(:client, :product, :timestamp, :subscribed)
    end
  end
end
