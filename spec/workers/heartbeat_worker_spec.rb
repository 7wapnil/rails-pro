describe Radar::HeartbeatWorker do
  let(:alive_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<alive product="3" timestamp="1532353925315" subscribed="1"/>'
  end
  let(:non_alive_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<alive product="2" timestamp="1532353925316" subscribed="0"/>'
  end
  let(:wrong_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<feed/>'
  end

  it { is_expected.to be_processed_in :critical }

  describe '.perform' do
    context 'on valid input' do
      it 'should pass correct alive message to Heartbeat service' do
        allow(Heartbeat::Service).to receive(:call)
        subject.perform(alive_xml)
        expect(Heartbeat::Service)
          .to have_received(:call)
          .with(
            client: instance_of(OddsFeed::Radar::Client),
            product: 3,
            timestamp: Time.at(1_532_353_925_315).to_datetime,
            alive: true
          )
      end
      it 'should pass correct non alive message to Heartbeat service' do
        allow(Heartbeat::Service).to receive(:call)
        subject.perform(non_alive_xml)
        expect(Heartbeat::Service)
          .to have_received(:call)
          .with(
            client: instance_of(OddsFeed::Radar::Client),
            product: 2,
            timestamp: Time.at(1_532_353_925_316).to_datetime,
            alive: false
          )
      end
    end
    context 'on invalid input' do
      it 'should not handle non-xml input' do
        expect { subject.perform('non-xml') }
          .to raise_error(REXML::ParseException)
      end

      it 'should not handle wrong xml' do
        expect { subject.perform(wrong_xml) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
