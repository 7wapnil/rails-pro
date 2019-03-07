describe OddsFeed::Radar::BetStopHandler do
  let(:base_payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<bet_stop timestamp="1532353934098" product="3" '\
      'event_id="sr:match:471123" groups="all"/>'
    )
  end

  let(:event) { create(:event, external_id: 'sr:match:471123') }

  describe 'market_status update' do
    let(:market_status_class) { OddsFeed::Radar::MarketStatus }

    let(:initial_state) { Market::ACTIVE }
    let(:not_active_states) { Market::STATUSES.except(:active) }
    let(:target_state) { not_active_states[not_active_states.keys.sample] }

    let!(:markets) do
      create_list(:market, 2, event: event, status: initial_state)
    end
    let!(:other_markets) { create_list(:market, 2, status: initial_state) }

    before do
      allow(market_status_class).to receive(:stop_status) { target_state }

      described_class.new(base_payload).handle

      markets.each(&:reload)
      other_markets.each(&:reload)
    end

    it 'affects payload event markets' do
      expect(markets.map(&:status).uniq).to eq([target_state])
    end

    it 'does not change other markets' do
      expect(other_markets.map(&:status).uniq).to eq([initial_state])
    end
  end
end
