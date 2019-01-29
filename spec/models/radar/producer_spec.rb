describe Radar::Producer do
  let(:snapshot_id) { Faker::Number.number(8).to_i }
  let(:recovery_time) { Faker::Date.backward(14).to_datetime }
  let(:another_producer) do
    create(:producer,
           recover_requested_at: producer.recover_requested_at - 1.day)
  end
  let(:producer) do
    create(:producer,
           recover_requested_at: recovery_time,
           recovery_snapshot_id: snapshot_id)
  end
  let(:live_producer) { create(:liveodds_producer) }
  let(:prematch_producer) { create(:prematch_producer) }
  let(:real_producers_set) { [live_producer, prematch_producer] }

  it { is_expected.to have_many(:events) }

  it 'emits websocket event on update' do
    producer.update(state: Radar::Producer::RECOVERING)
    expect(WebSocket::Client.instance)
      .to have_received(:trigger)
      .with(SubscriptionFields::PROVIDER_UPDATED, producer)
      .at_least(:once)
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

  describe '#unsubscribe!' do
    it 'ignored for unsubscribed producers' do
      allow(producer).to receive_messages(
        'unsubscribed!' => nil,
        'unsubscribed?' => true
      )
      producer.unsubscribe!
      expect(producer).not_to have_received('unsubscribed!')
    end

    it 'unsubscribes subscribed producer' do
      allow(producer).to receive_messages(
        'unsubscribe!' => nil,
        'subscribed?' => true
      )
      producer.unsubscribe!
      expect(producer)
        .to have_received('unsubscribe!').once
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
        allow(producer).to receive(:unsubscribed?).and_return(true)
        allow(OddsFeed::Radar::SubscriptionRecovery).to receive(:call)
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
  end

  describe '.unsubscribe!' do
    it 'ignores unsubscribed producer' do
      producer.update(state: described_class::UNSUBSCRIBED)
      producer.unsubscribe!
      expect(producer).to have_attributes(
        state: described_class::UNSUBSCRIBED,
        recovery_snapshot_id: snapshot_id,
        recover_requested_at: recovery_time
      )
    end

    [described_class::HEALTHY, described_class::RECOVERING].each do |state|
      context "with #{state} producer" do
        before do
          producer.update(state: state)
          producer.unsubscribe!
        end

        it 'clears recovery snapshot id' do
          expect(producer.recovery_snapshot_id).to eq nil
        end

        it 'clears recovery request time' do
          expect(producer.recover_requested_at).to eq nil
        end
      end
    end
  end

  describe '#recovery_completed!' do
    it 'sets healthy state' do
      producer.recovery_completed!
      expect(producer.state).to eq Radar::Producer::HEALTHY
    end
  end
end
