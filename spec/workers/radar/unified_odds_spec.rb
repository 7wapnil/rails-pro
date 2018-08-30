describe Radar::UnifiedOdds do
  let(:minimal_valid_odds_change_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<odds_change/>'
  end

  let(:minimal_valid_alive_xml) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<alive/>'
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
      allow(subject).to receive(:handle)
    end

    it 'routes odds_change to Radar::OddsChangeHandler' do
      subject.work(minimal_valid_odds_change_xml)
      expect(subject)
        .to have_received(:handle)
        .with(instance_of(OddsFeed::Radar::OddsChangeHandler))
    end

    it 'routes alive to Radar::AliveHandler' do
      subject.work(minimal_valid_alive_xml)
      expect(subject)
        .to have_received(:handle)
        .with(instance_of(OddsFeed::Radar::AliveHandler))
    end

    it 'routes alive to Radar::FixtureChangeHandler' do
      subject.work(minimal_valid_fixture_change_xml)
      expect(subject)
        .to have_received(:handle)
        .with(instance_of(OddsFeed::Radar::FixtureChangeHandler))
    end

    it 'raises NotImplementedError on any unknown input' do
      expect { subject.work('rubbish') }
        .to raise_error(NotImplementedError)
    end
  end
end
