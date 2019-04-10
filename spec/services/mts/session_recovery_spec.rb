describe Mts::SessionRecovery do
  describe '#recover_from_network_failure!' do
    before do
      allow(subject).to receive(:clear_session_failed_at)

      subject.recover_from_network_failure!
    end

    it 'does nothing if network failure is not registered' do
      allow(subject).to receive(:session_failed_at).and_return(nil)
    end

    context 'network failure registered' do
      before do
        allow(subject).to receive(:session_failed_at) { 2.minutes.ago }
        subject.recover_from_network_failure!
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
        allow(subject).to receive(:session_failed_at).and_return(nil)

        Timecop.freeze do
          subject.register_failure!

          expect(subject)
            .to have_received(:update_session_failed_at)
            .with(Time.zone.now)
            .once
        end
      end

      it 'triggers application state update' do
        expect(WebSocket::Client.instance)
          .to receive(:trigger_application_state_update)

        subject.register_failure!
      end
    end
  end
end
