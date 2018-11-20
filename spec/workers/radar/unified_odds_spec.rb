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

  describe '.routing_key' do
    subject(:key) { described_class.routing_key }

    context 'without environment setup' do
      let(:time_pattern) { '1%H%M%S%L' }
      it 'returns array of keys to listen all and generates node id' do
        Timecop.freeze do
          time = Time.now.strftime(time_pattern)
          expect(key).to match_array(
            [
              "*.*.*.*.*.*.*.#{time}.#",
              '*.*.*.*.*.*.*.-.#'
            ]
          )
        end
      end
    end

    context 'with ENV overrides' do
      it 'returns node_id key with provided key' do
        allow(ENV).to receive(:[])
          .with('RADAR_MQ_NODE_ID').and_return('777')
        allow(ENV).to receive(:[])
          .with('RADAR_MQ_LISTEN_ALL').and_return(nil)
        expect(key).to match_array(
          [
            '*.*.*.*.*.*.*.777.#',
            '*.*.*.*.*.*.*.-.#'
          ]
        )
      end

      it 'drop listen all key if necessary' do
        allow(ENV).to receive(:[])
          .with('RADAR_MQ_NODE_ID').and_return('123')
        allow(ENV).to receive(:[])
          .with('RADAR_MQ_LISTEN_ALL').and_return('false')
        expect(key).to match_array(
          [
            '*.*.*.*.*.*.*.123.#'
          ]
        )
      end
    end
    context 'explicit argument overrides all' do
      subject(:key) do
        described_class.routing_key(node_id: 666, listen_all: false)
      end
      it 'returns array based on params passed' do
        allow(ENV).to receive(:[])
          .with('RADAR_MQ_NODE_ID').and_return('777')
        allow(ENV).to receive(:[])
          .with('RADAR_MQ_LISTEN_ALL').and_return('true')
        expect(key).to match_array(
          [
            '*.*.*.*.*.*.*.666.#'
          ]
        )
      end
    end
  end
end
