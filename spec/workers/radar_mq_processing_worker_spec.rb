describe RadarMqProcessingWorker do
  it { is_expected.to be_processed_in :mq }

  describe '.perform' do
    xit 'passes odds_change to EventProcessingWorker'
    xit 'passes fixtures_fixture to EventProcessingWorker'
    xit 'raises NotImplementedError on any unknown input'
  end
end
