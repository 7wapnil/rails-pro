describe Radar::AliveMessage do
  let(:valid_timestamp) { Time.now.utc.to_i }
  let(:valid_timestamp_datetime) { Time.at(valid_timestamp.to_i).to_datetime }

  let(:subscribed_heartbeat_xml) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<alive product="1" timestamp="' + valid_timestamp.to_s +
        '" subscribed="1"/>'
    )['alive']
  end

  let(:unsubscribed_heartbeat_xml) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<alive product="3" timestamp="' + valid_timestamp.to_s +
        '" subscribed="0"/>'
    )['alive']
  end

  describe '#from_hash' do
    subject { Radar::AliveMessage }

    context 'with subscribed heartbeat' do
      let(:message) { subject.from_hash(subscribed_heartbeat_xml) }

      it 'converts product id' do
        expect(message.product_id).to eq 1
      end
      it 'converts reported_at' do
        expect(message.reported_at).to eq valid_timestamp_datetime
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
        expect(message.reported_at).to eq valid_timestamp_datetime
      end
      it 'converts subscription' do
        expect(message.subscribed).to be false
      end
    end
  end

  context '.process!' do
    describe '.subscribed_message_save' do
      let(:time) { Time.local(2018, 12, 1, 10, 5, 0) }
      let(:message) do
        build(:alive_message,
              product_id: 1, reported_at: time, subscribed: true)
      end

      before do
        Timecop.freeze(Time.local(2018, 9, 1, 10, 5, 0))
      end

      after do
        Timecop.return
      end

      it 'reports subscribed state' do
        expect(message)
          .to receive(:subscribed!).with(time).once
        message.process!
      end

      it 'raises failure flag' do
        message.process!
        expect(ApplicationState.instance.flags)
          .to_not include(message.producer.failure_flag_key)
      end
    end
    describe '.unsubscribed_message_save' do
      let(:time) { Time.local(2018, 12, 1, 10, 5, 0) }
      let(:message) do
        build(:alive_message,
              product_id: 1, reported_at: time, subscribed: false)
      end

      before do
        Timecop.freeze(Time.local(2018, 9, 1, 10, 5, 0))
      end

      after do
        Timecop.return
      end

      it 'reports subscribed state' do
        expect(message)
          .to receive(:recover_subscription!).once
        message.process!
      end

      it 'raises failure flag' do
        message.process!
        expect(ApplicationState.instance.flags)
          .to include(message.producer.failure_flag_key)
      end
    end
  end
end
