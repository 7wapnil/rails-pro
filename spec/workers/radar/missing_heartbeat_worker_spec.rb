describe Radar::MissingHeartbeatWorker do
  describe '.perform' do
    it 'perform subscription expiration check for each available producer' do
      # rubocop:disable RSpec/VerifiedDoubles
      producer = double(:producer)
      producer_two = double(:producer)
      # rubocop:enable RSpec/VerifiedDoubles
      producers = [producer, producer_two]
      expect(
        Radar::Producer
      ).to receive(:available_producers).and_return producers

      expect(producer).to receive(:check_subscription_expiration)
      expect(producer_two).to receive(:check_subscription_expiration)

      subject.perform
    end
  end
end
