describe RadarMqProcessingWorker do
  let(:minimal_valid_odds_change_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<odds_change/>'
  end
  let(:minimal_valid_odds_change_hash) do
    Nori.new.parse(minimal_valid_odds_change_xml)
  end

  it { is_expected.to be_processed_in :mq }

  describe '.perform' do
    it 'should route odds_change to EventProcessingWorker' do
      RadarMqProcessingWorker.new.perform(minimal_valid_odds_change_xml)
      expect(EventProcessingWorker)
        .to have_enqueued_sidekiq_job(minimal_valid_odds_change_hash)
    end
    it 'should raise NotImplementedError on any unknown input' do
      expect do
        RadarMqProcessingWorker.new.perform('rubbish')
      end.to raise_error(NotImplementedError)
    end
  end
end
