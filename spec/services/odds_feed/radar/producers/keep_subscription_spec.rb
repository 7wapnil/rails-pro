# frozen_string_literal: true

describe OddsFeed::Radar::Producers::KeepSubscription do
  subject { described_class.call(params) }

  let(:params) { { producer: producer, requested_at: requested_at } }

  shared_examples 'keeps subscription correct' do
    let(:heartbeat_limits) do
      OddsFeed::Radar::Producers::Heartbeatable::HEARTBEAT_INTERVAL_LIMITS
    end
    let(:heartbeat_limit) { heartbeat_limits[producer_code] }

    let(:last_subscribed_at) { heartbeat_limit.ago + 1.second }
    let(:control_state) { ::Radar::Producer::HEALTHY }

    let(:requested_at) { Time.zone.now.change(usec: 0) }
    let(:producer) do
      create(:producer,
             code: producer_code,
             state: control_state,
             last_subscribed_at: last_subscribed_at)
    end

    before do
      allow(::Radar::Producer).to receive(:recovery_disabled?).and_return(false)
      allow(OddsFeed::Radar::Producers::RequestRecovery)
        .to receive(:call)
        .and_return(true)
    end

    it 'stores successful alive message time' do
      subject
      expect(producer.reload).to have_attributes(
        state: control_state,
        last_subscribed_at: requested_at
      )
    end

    it 'proceeds successfully' do
      expect(subject).to eq(true)
    end

    context 'when heartbeat is expired' do
      let(:last_subscribed_at) { heartbeat_limit.ago - 1.second }

      it 'requests recovery' do
        expect(OddsFeed::Radar::Producers::RequestRecovery)
          .to receive(:call)
          .with(producer: producer)
        subject
      end

      it 'stores successful alive message time' do
        subject
        expect(producer.reload).to have_attributes(
          state: control_state,
          last_subscribed_at: requested_at
        )
      end

      it 'proceeds successfully' do
        expect(subject).to eq(true)
      end

      context 'when producer is already recovering' do
        let(:control_state) { ::Radar::Producer::RECOVERING }

        it 'requests recovery' do
          expect(OddsFeed::Radar::Producers::RequestRecovery)
            .to receive(:call)
            .with(producer: producer)
          subject
        end

        it 'stores successful alive message time' do
          subject
          expect(producer.reload).to have_attributes(
            state: control_state,
            last_subscribed_at: requested_at
          )
        end
      end

      context 'when recovery is disabled' do
        let(:control_state) { ::Radar::Producer::UNSUBSCRIBED }

        before do
          allow(::Radar::Producer)
            .to receive(:recovery_disabled?)
            .and_return(true)
        end

        it 'skips recovery and recognizes producer as subscribed' do
          subject
          expect(producer.reload).to have_attributes(
            state: ::Radar::Producer::HEALTHY,
            last_subscribed_at: requested_at
          )
        end

        it 'proceeds successfully' do
          expect(subject).to eq(true)
        end
      end

      context 'on failed recovery' do
        before do
          allow(OddsFeed::Radar::Producers::RequestRecovery)
            .to receive(:call)
            .and_return(false)
        end

        it 'does not re-write last subscription time' do
          expect { subject }.not_to(change(producer, :reload))
        end

        it 'fails' do
          expect(subject).to eq(false)
        end
      end

      context 'on failed SQL update' do
        before { allow(producer).to receive(:update).and_return(false) }

        it 'fails' do
          expect(subject).to eq(false)
        end
      end
    end
  end

  context 'on live producer' do
    it_behaves_like 'keeps subscription correct' do
      let(:producer_code) { ::Radar::Producer::LIVE_PROVIDER_CODE }
    end
  end

  context 'on prematch producer' do
    it_behaves_like 'keeps subscription correct' do
      let(:producer_code) { ::Radar::Producer::PREMATCH_PROVIDER_CODE }
    end
  end
end
