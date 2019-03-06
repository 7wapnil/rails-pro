describe OddsFeed::Radar::BetStopHandler do
  let(:base_payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<bet_stop timestamp="1532353934098" product="3" '\
      'event_id="sr:match:471123" groups="all"/>'
    )
  end

  let(:event) { create(:event, external_id: 'sr:match:471123') }

  shared_context 'handler state transition spec' do
    let(:payload) do
      base_payload.tap do |payload|
        payload['bet_stop']['market_status'] =
          OddsFeed::Radar::MarketStatus.code(market_status)
      end
    end

    let(:initial_state) { Market::ACTIVE }

    let!(:markets) do
      create_list(:market, 2, event: event, status: initial_state)
    end
    let!(:other_markets) { create_list(:market, 2, status: initial_state) }

    before do
      described_class.new(payload).handle
      markets.each(&:reload)
      other_markets.each(&:reload)
    end

    it 'affects payload event markets' do
      expect(markets.map(&:status).uniq).to eq([expected_state])
    end

    it 'does not change other markets' do
      expect(other_markets.map(&:status).uniq).to eq([initial_state])
    end
  end

  context 'when market_status is missing' do
    include_context 'handler state transition spec' do
      let(:market_status) { nil }
      let(:expected_state) { Market::SUSPENDED }
    end
  end

  context 'when market_status is suspended' do
    include_context 'handler state transition spec' do
      let(:market_status) { OddsFeed::Radar::MarketStatus::SUSPENDED }
      let(:expected_state) { Market::SUSPENDED }
    end
  end

  context 'when market_status is not suspended, e.g. inactive' do
    include_context 'handler state transition spec' do
      let(:market_status) { OddsFeed::Radar::MarketStatus::INACTIVE }
      let(:expected_state) { Market::INACTIVE }
    end
  end
end
