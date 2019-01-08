describe OddsFeed::Radar::SnapshotCompleteHandler do
  let(:producer) { create(:producer) }

  before do
    allow(producer).to receive(:recovery_completed!)
    allow(::Radar::Producer).to receive(:find).with(producer.id) { producer }
  end

  describe '.handle' do
    context 'with snapshot complete for given producer' do
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

    context 'with snapshot complete, but faulty id' do
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
  end
end
