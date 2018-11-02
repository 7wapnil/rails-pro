describe Radar::MissingHeartbeatWorker do
  describe '.perform' do
    it 'perform subscription expiration check for each available producer' do
      producer = double(:producer)
      producer_two = double(:producer)
      producers = [producer, producer_two]
      Radar::Producer.stub(:available_producers).and_return producers
      expect(producer).to receive(:check_subscription_expiration)
      expect(producer_two).to receive(:check_subscription_expiration)

      subject.perform
    end
  end
end
