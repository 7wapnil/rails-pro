describe RadarMqProcessingWorker do
  let(:minimal_valid_odds_change_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<odds_change/>'
  end

  it { is_expected.to be_processed_in :mq }

  describe '.perform' do
    it 'passes odds_change to EventProcessingWorker' do
      expect do
        RadarMqProcessingWorker.new.perform(minimal_valid_odds_change_xml)
      end.to change(EventProcessingWorker.jobs, :size).by(1)
    end
    xit 'passes fixtures_fixture to EventProcessingWorker'
    xit 'raises NotImplementedError on any unknown input'
  end
end
