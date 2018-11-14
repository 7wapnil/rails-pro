describe Mts::SessionRecovery do
  describe '#recover_from_network_failure!' do
    before do
      allow(subject).to receive(:recover_producer_subscriptions!)
      allow(subject).to receive(:clear_session_failed_at)

      subject.recover_from_network_failure!
    end

    it 'does nothing if network failure is not registered' do
      allow(subject).to receive(:session_failed_at) { nil }

      expect(subject).not_to have_received(:recover_producer_subscriptions!)
    end

    context 'network failure registered' do
      before do
        allow(subject).to receive(:session_failed_at) { 2.minutes.ago }
        subject.recover_from_network_failure!
      end

      it 'calls #recover_producer_subscriptions!' do
        expect(subject).to have_received(:recover_producer_subscriptions!)
      end

      it 'removes network failure flag' do
        expect(subject).to have_received(:clear_session_failed_at)
      end
    end
  end

  describe '#register_failure!' do
    before { allow(subject).to receive(:update_session_failed_at) }

    context 'network failure registered' do
      it 'does nothing if network failure is registered' do
        allow(subject).to receive(:session_failed_at) { 2.minutes.ago }

        subject.register_failure!

        expect(subject).not_to have_received(:update_session_failed_at)
      end
    end

    context 'network failure not registered' do
      it 'writes network failure flag' do
        allow(subject).to receive(:session_failed_at) { nil }

        Timecop.freeze do
          subject.register_failure!

          expect(subject)
            .to have_received(:update_session_failed_at)
            .with(Time.zone.now)
            .once
        end
      end
    end
  end

  describe '#recover_producer_subscriptions' do
    it 'calls #recover_subscription! on every producer' do
      producer_double = double('producer')
      allow(Radar::Producer).to receive(:find_by_id) { producer_double }
      expect(producer_double)
        .to receive(:recover_subscription!)
        .exactly(Radar::Producer::RADAR_AVAILABLE_PRODUCERS.count)
        .times

      subject.send(:recover_producer_subscriptions!)
    end
  end
end
