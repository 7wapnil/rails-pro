describe Heartbeat::Service do
  describe '.call' do
    it 'has correct signature' do
      expect(subject)
        .to respond_to(:call)
        .with_keywords(:client, :product, :timestamp, :subscribed)
    end
  end
end
