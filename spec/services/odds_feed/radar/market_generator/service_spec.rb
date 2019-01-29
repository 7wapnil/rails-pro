describe OddsFeed::Radar::MarketGenerator::Service do
  let(:markets_data) do
    XmlParser
      .parse(file_fixture('odds_change_message.xml').read)
      .dig('odds_change', 'odds', 'market')
  end

  let(:event)      { create(:event) }

  describe 'market attributes' do
    subject { described_class.new(event.id, markets_data) }

    it 'assigns market template category' do
      market_templates = markets_data.map do |payload|
        create(:market_template,
               external_id: payload['id'],
               category: MarketTemplate.categories.keys.sample)
      end

      subject.send(:build)

      markets = subject.instance_variable_get(:@markets)

      markets.each_with_index do |market, index|
        market_template = market_templates[index]
        expect(market.category).to eq(market_template.category)
      end
    end
  end

  describe '#call' do
    subject { described_class.call(event.id, markets_data) }

    let(:web_socket) { double }
    let(:odds)       { build_stubbed_list(:odd, 5) }
    let(:markets)    { build_stubbed_list(:market, markets_data.count) }

    before do
      allow(WebSocket::Client).to receive(:instance).and_return(web_socket)
      allow(web_socket).to        receive(:trigger_event_update)
      allow(web_socket).to        receive(:trigger_market_update)
      allow(web_socket).to        receive(:trigger_provider_update)

      allow(OddsFeed::Radar::MarketGenerator::OddsGenerator)
        .to receive(:call)
        .and_return(odds)

      allow_any_instance_of(OddsFeed::Radar::MarketGenerator::MarketData)
        .to receive(:name)
      allow_any_instance_of(OddsFeed::Radar::MarketGenerator::MarketData)
        .to receive(:category)
      allow(Market).to receive(:new).and_return(*markets)

      allow(Market).to receive(:import)
      allow(Odd).to    receive(:import)
    end

    context 'build markets' do
      context 'proceed only valid markets' do
        let(:valid_markets_count) { rand(markets_data.count) }
        let(:valid_markets) { build_stubbed_list(:market, valid_markets_count) }
        let(:invalid_markets) do
          build_stubbed_list(
            :market,
            markets_data.count - valid_markets_count,
            name: nil
          )
        end
        let(:markets) { [*valid_markets, *invalid_markets] }

        it do
          expect(OddsFeed::Radar::MarketGenerator::OddsGenerator)
            .to receive(:call)
            .exactly(valid_markets_count)
            .times
          subject
        end

        it { expect { subject }.not_to raise_error }
      end
    end

    context 'import' do
      it 'performed' do
        expect(Market).to receive(:import).with(markets, hash_including)
        expect(Odd)
          .to receive(:import)
          .with(array_including(odds), hash_including)

        subject
      end

      it 'emit web-socket events' do
        expect(web_socket).to receive(:trigger_market_update)
        subject
      end
    end
  end
end
