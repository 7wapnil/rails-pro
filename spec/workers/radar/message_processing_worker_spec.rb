describe Radar::MessageProcessingWorker do
  let(:minimal_valid_odds_change_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<odds_change/>'
  end

  let(:minimal_valid_odds_change_hash) do
    Hash.from_xml(minimal_valid_odds_change_xml)
  end

  let(:minimal_valid_alive_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<alive/>'
  end

  let(:minimal_valid_alive_hash) do
    Hash.from_xml(minimal_valid_alive_xml)
  end

  it { is_expected.to be_processed_in :mq }

  describe '.perform' do
    it 'routes odds_change to EventProcessingWorker' do
      Radar::MessageProcessingWorker.new.perform(minimal_valid_odds_change_xml)
      expect(Radar::EventProcessingWorker)
        .to have_enqueued_sidekiq_job(minimal_valid_odds_change_hash)
    end

    it 'routes alive to Radar::HeartbeatWorker' do
      Radar::MessageProcessingWorker.new.perform(minimal_valid_alive_xml)
      expect(Radar::HeartbeatWorker)
        .to have_enqueued_sidekiq_job(minimal_valid_alive_hash)
    end

    it 'raises NotImplementedError on any unknown input' do
      expect do
        Radar::MessageProcessingWorker.new.perform('rubbish')
      end.to raise_error(NotImplementedError)
    end
  end
end
