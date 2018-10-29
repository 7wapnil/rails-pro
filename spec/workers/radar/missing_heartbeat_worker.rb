describe Radar::MissingHeartbeatWorker do
  describe '.perform' do
    context 'all products expired' do
      before do
        allow_any_instance_of(OddsFeed::Radar::ProducerSubscriptionState)
          .to receive(:last_subscribed_reported_timestamp)
          .and_return(1.hour.ago)
      end
      it 'calls recovery for each product' do
        expect(OddsFeed::Radar::SubscriptionRecovery).to receive(:call).twice
        subject.perform
      end

      xit 'emits WS events for each market'
    end
  end
end
