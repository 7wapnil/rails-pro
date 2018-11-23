describe Radar::AliveMessage do
  let(:report_timestamp) { Time.now.utc.to_i }
  let(:reported_at) { Time.at(report_timestamp.to_i).to_datetime }

  let(:subscribed_heartbeat_xml) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<alive product="1" timestamp="' + report_timestamp.to_s +
        '" subscribed="1"/>'
    )['alive']
  end

  let(:unsubscribed_heartbeat_xml) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<alive product="3" timestamp="' + report_timestamp.to_s +
        '" subscribed="0"/>'
    )['alive']
  end

  before do
    allow(OddsFeed::Radar::SubscriptionRecovery)
      .to receive(:call)
  end

  describe '#from_hash' do
    subject { Radar::AliveMessage }

    context 'with subscribed heartbeat' do
      let(:message) { subject.from_hash(subscribed_heartbeat_xml) }

      it 'converts product id' do
        expect(message.product_id).to eq 1
      end
      it 'converts reported_at' do
        expect(message.reported_at).to eq reported_at
      end
      it 'converts subscription' do
        expect(message.subscribed).to be true
      end
    end

    context 'with unsubscribed heartbeat' do
      let(:message) { subject.from_hash(unsubscribed_heartbeat_xml) }

      it 'converts product id' do
        expect(message.product_id).to eq 3
      end
      it 'converts reported_at' do
        expect(message.reported_at).to eq reported_at
      end
      it 'converts subscription' do
        expect(message.subscribed).to be false
      end
    end
  end

  describe '.process!' do
    before { Timecop.freeze(reported_at) }
    after { Timecop.return }

    describe '.process_subscribed_message' do
      let(:message) do
        build(:alive_message,
              product_id: 1, reported_at: reported_at, subscribed: true)
      end

      before do
        allow(message).to receive(:subscribed!)
        message.process!
      end

      it 'reports subscribed state' do
        expect(message)
          .to have_received(:subscribed!).with(reported_at).once
      end

      it 'removes failure flag' do
        expect(ApplicationState.instance.live_connected).to be_truthy
      end
    end

    describe '.process_unsubscribed_message' do
      let(:message) do
        build(:alive_message,
              product_id: 1, reported_at: reported_at, subscribed: false)
      end

      before do
        allow(message).to receive(:recover_subscription!)
        message.process!
      end

      it 'initiates recovery' do
        expect(message).to have_received(:recover_subscription!).once
      end

      it 'raises failure flag' do
        expect(ApplicationState.instance.live_connected).to be_falsy
      end
    end
  end
end
