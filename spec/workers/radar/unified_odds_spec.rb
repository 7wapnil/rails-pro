describe Radar::UnifiedOdds do
  let(:minimal_valid_odds_change_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<odds_change/>'
  end

  let(:minimal_valid_alive_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<alive/>'
  end

  let(:minimal_valid_bet_settlement_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<bet_settlement/>'
  end

  let(:minimal_valid_bet_stop_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<bet_stop/>'
  end

  let(:minimal_valid_bet_cancel_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<bet_cancel/>'
  end

  let(:minimal_valid_fixture_change_xml) do
    <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <fixture_change event_id="sr:match:1234"
                      change_type="1"
                      product="1" />
    XML
  end

  describe 'work' do
    before do
      Sneakers.logger.level = Logger::ERROR
    end

    it 'routes odds_change to Radar::OddsChangeWorker' do
      expect(Radar::OddsChangeWorker)
        .to receive(:perform_async)
        .with(minimal_valid_odds_change_xml)
      subject.work(minimal_valid_odds_change_xml)
    end

    it 'routes alive to Radar::AliveWorker' do
      expect(Radar::AliveWorker)
        .to receive(:perform_async)
        .with(minimal_valid_alive_xml)
      subject.work(minimal_valid_alive_xml)
    end

    it 'routes alive to Radar::BetSettlementWorker' do
      expect(Radar::BetSettlementWorker)
        .to receive(:perform_async)
        .with(minimal_valid_bet_settlement_xml)
      subject.work(minimal_valid_bet_settlement_xml)
    end

    it 'routes bet stop to Radar::BetStopWorker' do
      expect(Radar::BetStopWorker)
        .to receive(:perform_async)
        .with(minimal_valid_bet_stop_xml)
      subject.work(minimal_valid_bet_stop_xml)
    end

    it 'routes bet cancel to Radar::BetCancelWorker' do
      expect(Radar::BetCancelWorker)
        .to receive(:perform_async)
        .with(minimal_valid_bet_cancel_xml)
      subject.work(minimal_valid_bet_cancel_xml)
    end

    it 'routes alive to Radar::FixtureChangeWorker' do
      expect(Radar::FixtureChangeWorker)
        .to receive(:perform_async)
        .with(minimal_valid_fixture_change_xml)
      subject.work(minimal_valid_fixture_change_xml)
    end

    it 'raises NotImplementedError on any unknown input' do
      expect { subject.work('rubbish') }
        .to raise_error(NotImplementedError)
    end
  end
end
