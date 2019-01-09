describe OddsFeed::Radar::SnapshotCompleteHandler do
  let(:producer) { create(:producer, state: Radar::Producer::RECOVERING) }

  before do
    allow(producer).to receive(:recovery_completed!)
    allow(::Radar::Producer).to receive(:find).with(producer.id) { producer }
  end

  describe '.handle' do
    context 'when snapshot complete for given producer' do
      let(:payload) do
        XmlParser.parse(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      "<snapshot_complete request_id=\"#{producer.recovery_snapshot_id}\" "\
      " timestamp=\"1234578\" product=\"#{producer.id}\"/>"
        )
      end

      before do
        described_class.new(payload).handle
      end

      it 'calls recovery_completed!' do
        expect(producer).to have_received(:recovery_completed!).once
      end
    end

    context 'when snapshot id does not match' do
      let(:payload) do
        XmlParser.parse(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      "<snapshot_complete request_id=\"#{producer.recovery_snapshot_id + 1}\" "\
      " timestamp=\"1234578\" product=\"#{producer.id}\"/>"
        )
      end

      it 'raises corresponding exception' do
        expect { described_class.new(payload).handle }
          .to raise_error(StandardError, 'Unknown snapshot completed')
      end
    end

    context 'when producer is not recoverable' do
      let(:payload) do
        XmlParser.parse(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      "<snapshot_complete request_id=\"#{producer.recovery_snapshot_id + 1}\" "\
      " timestamp=\"1234578\" product=\"#{producer.id}\"/>"
        )
      end

      [Radar::Producer::HEALTHY, Radar::Producer::UNSUBSCRIBED].each do |state|
        it "does not recover #{state} producer" do
          producer.update(state: state)

          expect(described_class.new(payload).handle).to be_falsey
        end
      end
    end
  end
end
