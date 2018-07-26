describe Radar::HeartbeatWorker do
  let(:alive_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<alive product="3" timestamp="1532353925315" subscribed="1"/>'
  end
  let(:non_alive_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<alive product="3" timestamp="1532353925315" subscribed="0"/>'
  end

  it { is_expected.to be_processed_in :critical }

  describe '.perform' do
    xit 'should pass correct product to Heartbeat service'
    xit 'should pass correct timestamp to Heartbeat service'
    xit 'should pass alive state to Heartbeat service'
    xit 'should pass non alive state to Heartbeat service'
  end
end
