describe Radar::Producer do
  let(:snapshot_id) { Faker::Number.number(8).to_i }
  let(:node_id) { Faker::Number.number(4).to_i }
  let(:recovery_time) { Faker::Date.backward(14).to_datetime }
  let(:another_producer) do
    create(:producer,
           recover_requested_at: producer.recover_requested_at - 1.day)
  end
  let(:producer) do
    create(:producer,
           recover_requested_at: recovery_time,
           recovery_snapshot_id: snapshot_id,
           recovery_node_id: node_id,
           state: Radar::Producer::HEALTHY)
  end
  let(:live_producer) { create(:liveodds_producer) }
  let(:prematch_producer) { create(:prematch_producer) }
  let(:real_producers_set) { [live_producer, prematch_producer] }

  it { is_expected.to have_many(:events) }

  describe 'callbacks' do
    let!(:producer) { create(:producer, state: Radar::Producer::HEALTHY) }

    it 'emits websocket event on update' do
      expect(WebSocket::Client.instance)
        .to receive(:trigger_provider_update)
        .with(producer)
        .once

      producer.update(state: Radar::Producer::RECOVERING)
    end

    it 'emits websocket event on state update only' do
      expect(WebSocket::Client.instance)
        .not_to receive(:trigger_provider_update)
      producer.update(last_successful_subscribed_at: Time.zone.now)
    end
  end

  describe '#last_recovery_call_at' do
    before do
      producer
      another_producer
    end

    it 'returns newest recover_requested_at' do
      expect(described_class.last_recovery_call_at)
        .to eq producer.recover_requested_at
    end
  end

  describe '.live' do
    it 'returns live producer' do
      real_producers_set
      expect(described_class.live).to eq live_producer
    end
  end

  describe '.prematch' do
    it 'returns prematch producer' do
      real_producers_set
      expect(described_class.prematch).to eq prematch_producer
    end
  end

  describe '#live?' do
    it 'returns false for prematch code' do
      real_producers_set
      expect(prematch_producer).not_to be_live
    end

    it 'return true for live code' do
      real_producers_set
      expect(live_producer).to be_live
    end
  end

  describe '#prematch?' do
    it 'returns true for prematch code' do
      real_producers_set
      expect(prematch_producer).to be_prematch
    end

    it 'return false for live code' do
      real_producers_set
      expect(live_producer).not_to be_prematch
    end
  end

  describe '#subscribed?' do
    it 'returns false for non live code' do
      allow(producer).to receive(:state)
        .and_return(described_class::UNSUBSCRIBED)
      expect(producer).not_to be_live
    end

    described_class::SUBSCRIBED_STATES.values.each do |status|
      it "returns true for subscribed state #{status}" do
        allow(producer).to receive(:state) { status }
        expect(producer).to be_subscribed
      end
    end
  end

  describe '#unsubscribe_expired!' do
    include_context 'frozen_time'

    let(:limit) do
      described_class::HEARTBEAT_EXPIRATION_TIME_IN_SECONDS.seconds.ago
    end

    it 'returns false for not expired producer' do
      allow(producer)
        .to receive(:last_successful_subscribed_at) { limit + 1.second }
      expect(producer.unsubscribe_expired!).to be_falsey
    end

    it 'calls unsubscribe! when subscription expires' do
      allow(producer)
        .to receive(:last_successful_subscribed_at) { limit - 1.second }
      allow(producer).to receive(:unsubscribe!)
      producer.unsubscribe_expired!
      expect(producer).to have_received(:unsubscribe!).once
    end
  end

  describe '#subscribed!' do
    include_context 'frozen_time'

    let(:time) { Time.zone.now }

    it 'recovers unless subscribed producer' do
      allow(producer).to receive_messages(
        'recover!' => true,
        'subscribed?' => false
      )
      producer.subscribed!
      expect(producer).to have_received('recover!').once
    end

    it 'does not recover subscribed producer' do
      allow(producer).to receive_messages(
        'recover!' => true,
        'subscribed?' => true
      )
      producer.subscribed!
      expect(producer).not_to have_received('recover!')
    end

    it 'does not update to older timestamp' do
      producer.last_successful_subscribed_at = time
      expect(producer.subscribed!(subscribed_at: time)).to be_falsey
    end

    it 'updates timestamp' do
      producer.last_successful_subscribed_at = time - 1.second
      producer.subscribed!(subscribed_at: time)
      expect(producer.last_successful_subscribed_at).to eq time
    end

    it 'updates initial timestamp' do
      producer.last_successful_subscribed_at = nil
      producer.subscribed!(subscribed_at: time)
      expect(producer.last_successful_subscribed_at).to eq time
    end
  end

  describe '#recover!' do
    it 'ignores anything but unsusbscribed' do
      allow(producer).to receive(:unsubscribed?).and_return(false)
      allow(OddsFeed::Radar::SubscriptionRecovery).to receive(:call)
      producer.recover!
      expect(OddsFeed::Radar::SubscriptionRecovery).not_to receive(:call)
    end

    context 'when unsubscribed' do
      before do
        allow(producer).to receive(:recover_requested_at).and_return(1.hour.ago)
        allow(producer).to receive(:unsubscribed?).and_return(true)
        allow(OddsFeed::Radar::SubscriptionRecovery).to receive(:call) {
          producer
        }
        producer.recover!
      end

      it 'calls recovery service' do
        expect(OddsFeed::Radar::SubscriptionRecovery)
          .to have_received(:call).with(product: producer).once
      end

      it 'updates state to recovering' do
        expect(producer.state).to eq described_class::RECOVERING
      end
    end

    context 'when unsubscribed and rates not available' do
      let(:original_status) { described_class::UNSUBSCRIBED }

      before do
        producer.update(state: original_status)
        allow(producer)
          .to receive(:recover_requested_at).and_return(1.second.ago)
        allow(producer).to receive(:unsubscribed?).and_return(true)
        allow(OddsFeed::Radar::SubscriptionRecovery).to receive(:call)
        producer.recover!
      end

      it 'keeps original state' do
        expect(producer.state).to eq original_status
      end
    end
  end

  describe '#unsubscribe!' do
    include_context 'frozen_time'

    context 'with subscribed producer' do
      let(:last_successful_subscribed_at) { Faker::Time.backward(20) }

      before do
        allow(producer)
          .to receive_messages(
            'unsubscribed!' => nil,
            'subscribed?' => true,
            'recovery_requested_recently?' => false
          )
        producer
          .update(
            last_successful_subscribed_at: last_successful_subscribed_at,
            last_disconnection_at: nil
          )
        producer.unsubscribe!
      end

      it 'unsubscribes producer' do
        expect(producer)
          .to have_received('unsubscribed!').once
      end

      it 'registers first disconnection' do
        expect(producer.last_disconnection_at)
          .to eq last_successful_subscribed_at
      end
    end

    context 'with recovering producer, but recovery not finished properly' do
      let(:last_disconnection_at) { Faker::Time.backward(20) }

      before do
        allow(producer).to receive_messages(
          'unsubscribed!' => nil,
          'recovery_requested_recently?' => false,
          'last_disconnection_at' => last_disconnection_at
        )
        producer.unsubscribe!
      end

      it 'does not overwrite disconnection time' do
        expect(producer.last_disconnection_at).to eq last_disconnection_at
      end
    end

    it 'ignores unsubscription when had recovery recently' do
      recent_recovery_time =
        described_class::RECOVERY_WAIT_TIME_IN_SECONDS.seconds.ago
      producer
        .update(
          state: described_class::RECOVERING,
          recover_requested_at: recent_recovery_time
        )
      producer.unsubscribe!
      expect(producer).to have_attributes(
        state: described_class::RECOVERING,
        recovery_snapshot_id: snapshot_id,
        recover_requested_at: recent_recovery_time,
        recovery_node_id: node_id
      )
    end

    [described_class::HEALTHY, described_class::RECOVERING].each do |state|
      context "with #{state} producer and no recent recovery" do
        before do
          non_recent_recovery_time =
            (described_class::RECOVERY_WAIT_TIME_IN_SECONDS + 1).seconds.ago
          producer.update(
            state: state,
            recover_requested_at: non_recent_recovery_time
          )
          allow(producer).to receive(:recover!)
          producer.unsubscribe!
        end

        it 'clears recovery snapshot id' do
          expect(producer.recovery_snapshot_id).to eq nil
        end

        it 'clears recovery request time' do
          expect(producer.recover_requested_at).to eq nil
        end

        it 'clears recovery node id' do
          expect(producer.recovery_node_id).to eq nil
        end

        it 'does not call recovery!' do
          expect(producer).not_to have_received(:recover!)
        end
      end

      context "with #{state} producer, no recent recovery, with recovery" do
        before do
          non_recent_recovery_time =
            (described_class::RECOVERY_WAIT_TIME_IN_SECONDS + 1).seconds.ago
          producer.update(
            state: state,
            recover_requested_at: non_recent_recovery_time
          )
          allow(producer).to receive(:recover!)
          producer.unsubscribe!(with_recovery: true)
        end

        it 'calls recovery!' do
          expect(producer).to have_received(:recover!).once
        end
      end
    end
  end

  describe '#recovery_completed!' do
    before do
      producer.recovery_completed!
    end

    it 'sets healthy state' do
      expect(producer.state).to eq Radar::Producer::HEALTHY
    end

    it 'cleans last disconnection time' do
      expect(producer.last_disconnection_at).to eq nil
    end
  end
end
