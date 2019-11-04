# frozen_string_literal: true

describe OddsFeed::Radar::Producers::CheckHeartbeat do
  subject { described_class.call(producer: producer) }

  shared_examples 'has working heartbeat checks' do
    let(:heartbeat_limits) do
      OddsFeed::Radar::Producers::Heartbeatable::HEARTBEAT_INTERVAL_LIMITS
    end
    let(:heartbeat_limit) { heartbeat_limits[producer_code] }

    let(:last_subscribed_at) { heartbeat_limit.ago.change(usec: 0) - 1.second }
    let(:control_state) { ::Radar::Producer::HEALTHY }
    let(:last_disconnected_at) {}

    let(:producer) do
      create(:producer,
             code: producer_code,
             state: control_state,
             last_disconnected_at: last_disconnected_at,
             last_subscribed_at: last_subscribed_at)
    end

    it 'registers disconnection on heartbeat expiration' do
      subject
      expect(producer.reload).to have_attributes(
        state: ::Radar::Producer::UNSUBSCRIBED,
        last_disconnected_at: last_subscribed_at
      )
    end

    it 'proceeds successfully' do
      expect(subject).to eq(true)
    end

    context 'when heartbeat is acceptable' do
      let(:last_subscribed_at) do
        heartbeat_limit.ago.change(usec: 0) + 1.second
      end

      it 'does not update producer' do
        expect { subject }.not_to(change(producer, :reload))
      end

      it 'fails' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is already registered last disconnection at' do
      let(:last_disconnected_at) { 5.seconds.ago.change(usec: 0) }

      it 'registers disconnection when state was HEALTHY' do
        subject
        expect(producer.reload).to have_attributes(
          state: ::Radar::Producer::UNSUBSCRIBED,
          last_disconnected_at: last_subscribed_at
        )
      end

      context 'but state was not HEALTHY' do
        let(:control_state) do
          [
            ::Radar::Producer::UNSUBSCRIBED,
            ::Radar::Producer::RECOVERING
          ].sample
        end

        it 'does not update producer' do
          expect { subject }.not_to(change(producer, :reload))
        end

        it 'fails' do
          expect(subject).to eq(false)
        end
      end
    end
  end

  context 'on live producer' do
    it_behaves_like 'has working heartbeat checks' do
      let(:producer_code) { ::Radar::Producer::LIVE_PROVIDER_CODE }
    end
  end

  context 'on prematch producer' do
    it_behaves_like 'has working heartbeat checks' do
      let(:producer_code) { ::Radar::Producer::PREMATCH_PROVIDER_CODE }
    end
  end
end
