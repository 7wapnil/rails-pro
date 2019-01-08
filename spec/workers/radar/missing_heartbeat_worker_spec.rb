describe Radar::MissingHeartbeatWorker do
  it { is_expected.to be_processed_in :radar_missing_heartbeat }

  describe '.perform' do
    context 'when performed' do
      let(:producer) { instance_double('Radar::Producer') }
      let(:producer_two) { instance_double('Radar::Producer') }

      before do
        allow(producer).to receive(:unsubscribe_expired!)
        allow(producer_two).to receive(:unsubscribe_expired!)
        producers = [producer, producer_two]
        allow(
          Radar::Producer
        ).to receive(:all).and_return producers

        subject.perform
      end

      it 'sends unsubscribe_expired! to first producer in the database' do
        expect(producer).to have_received(:unsubscribe_expired!)
      end

      it 'sends unsubscribe_expired! to second producer in the database' do
        expect(producer_two).to have_received(:unsubscribe_expired!)
      end
    end
  end
end
