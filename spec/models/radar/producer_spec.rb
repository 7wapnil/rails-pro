describe Radar::Producer do
  let(:another_producer) do
    create(:producer,
           recover_requested_at: producer.recover_requested_at - 1.day)
  end
  let(:producer) do
    create(:producer,
           recover_requested_at: Faker::Date.backward(14))
  end

  it { is_expected.to have_many(:events) }

  describe '#last_recovery_call_at' do
    before do
      producer
      another_producer
    end

    it 'returns newest recover_requested_at' do
      expect(described_class.last_recovery_call_at)
        .to eq another_producer.recover_requested_at
    end
  end

  describe '.live?' do
    it 'returns false for non live code' do
      allow(producer).to receive(:code).and_return(:none_live)
      expect(producer).not_to be_live
    end

    it 'return true for live code' do
      allow(producer).to receive(:code).and_return(:liveodds)
      expect(producer).to be_live
    end
  end

  describe '.subscribed?' do
    it 'returns false for non live code' do
      allow(producer).to receive(:state)
        .and_return(Radar::Producer::UNSUBSCRIBED)
      expect(producer).not_to be_live
    end

    Radar::Producer::SUBSCRIBED_STATES.values.each do |status|
      it "returns true for subscribed state #{status}" do
        allow(producer).to receive(:state) { status }
        expect(producer).to be_subscribed
      end
    end
  end

  describe '.unsubscribe_expired!' do
    before do
      Timecop.freeze(Time.now)
    end

    after do
      Timecop.return
    end

    let(:limit) { 60.seconds.ago }

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

  describe '.unsubscribe!' do
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

  describe '.subscribed!' do
    before do
      Timecop.freeze Time.zone.now
    end

    after do
      Timecop.return
    end

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

  describe '.recover!' do
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
        expect(producer.state).to eq Radar::Producer::RECOVERING
      end
    end
  end

  describe '.recovery_completed!' do
    it 'sets healthy state' do
      producer.recovery_completed!
      expect(producer.state).to eq Radar::Producer::HEALTHY
    end
  end
end
