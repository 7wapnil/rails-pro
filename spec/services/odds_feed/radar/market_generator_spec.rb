describe OddsFeed::Radar::MarketGenerator::Service do
  let(:market_payload) do
    data = XmlParser.parse(file_fixture('odds_change_message.xml').read)
    data['odds_change']['odds']['market']
  end
  let(:chosen_market) { nil }
  let(:event) { create(:event, external_id: 'sr:match:1234') }

  subject do
    OddsFeed::Radar::MarketGenerator::Service.new(event.id, chosen_market)
  end

  before do
    payload = {
      outcomes: {
        outcome: [
          { 'id': '1', name: 'Odd 1 name' },
          { 'id': '2', name: 'Odd 2 name' }
        ]
      }
    }.deep_stringify_keys

    create(:market_template, external_id: '123',
                             name: 'Template name',
                             payload: payload)
  end

  context 'market with outcomes' do
    let(:chosen_market) { market_payload[3] }
    let(:external_id) { 'sr:match:1234:123/set=2|game=3|point=1' }

    describe '#create_or_update_market!' do
      context 'initialized market already exists' do
        it 'updates existing market' do
          market_payload = {
            external_id: external_id,
            event: event,
            status: :active
          }

          initialized_market = build(:market, market_payload)
          existing_market = create(:market, market_payload)

          allow(subject)
            .to receive(:market)
            .and_return(initialized_market, existing_market)

          expect(existing_market).to receive(:assign_attributes).once

          expect(existing_market)
            .to receive(:save!)
            .and_raise(ActiveRecord::RecordInvalid)

          expect(existing_market)
            .to receive(:save!)
            .and_return(true)

          subject.send(:create_or_update_market!)
        end
      end
    end

    it 'generates new market if not exists in db' do
      subject.call
      market = Market.find_by(external_id: external_id)
      expect(market).not_to be_nil
    end

    it 'generates new market with default priority' do
      subject.call
      market = Market.find_by(external_id: external_id)
      expect(market.priority).to eq(1)
    end

    it 'sends websocket message on new market creation' do
      subject.call
      market = Market.find_by!(external_id: external_id)

      expect(WebSocket::Client.instance)
        .to have_received(:emit)
        .with(WebSocket::Signals::MARKET_CREATED,
              id: market.id.to_s,
              eventId: market.event.id.to_s)
    end

    it 'updates market if exists in db' do
      market = create(:market,
                      external_id: external_id,
                      event: event,
                      status: :active)
      subject.call
      updated_market = Market.find_by(external_id: external_id)
      expect(updated_market.updated_at).not_to eq(market.updated_at)
    end

    it 'does not send websocket message if market not change' do
      create(:market,
             external_id: external_id,
             event: event,
             name: 'transpiler value',
             priority: 0,
             status: :suspended)

      subject.call
      expect(WebSocket::Client.instance)
        .not_to have_received(:emit)
        .with(WebSocket::Signals::MARKET_UPDATED)
    end

    it 'sets appropriate status for market' do
      [
        { status: '-1', result: 'suspended' },
        { status: '0', result: 'inactive' },
        { status: '1', result: 'active' }
      ].each do |expectation|
        chosen_market['status'] = expectation[:status]
        subject.call
        market = Market.find_by(external_id: external_id)
        expect(market.status).to eq(expectation[:result])
      end
    end

    context 'odds' do
      it 'creates odds if not exist in db' do
        subject.call
        expect(Odd.find_by(external_id: "#{external_id}:1")).not_to be_nil
        expect(Odd.find_by(external_id: "#{external_id}:2")).not_to be_nil
      end

      it 'updates odds if exist in db' do
        market = create(:market,
                        external_id: external_id,
                        event: event,
                        status: :active)

        create(
          :odd,
          external_id: "#{external_id}:1",
          market: market,
          value: 1.0
        )

        create(
          :odd,
          external_id: "#{external_id}:2",
          market: market,
          value: 1.0
        )

        subject.call
        expect(Odd.find_by(external_id: "#{external_id}:1").value).to eq(1.3)
        expect(Odd.find_by(external_id: "#{external_id}:2").value).to eq(1.7)
      end

      it 'sends websocket message on new odd creation' do
        subject.call

        odd = Odd.find_by!(external_id: "#{external_id}:1")
        expect(WebSocket::Client.instance)
          .to have_received(:emit)
          .with(WebSocket::Signals::ODD_CREATED,
                id: odd.id.to_s,
                marketId: odd.market.id.to_s,
                eventId: odd.market.event.id.to_s)
      end
    end
  end

  context 'market without specifiers' do
    let(:chosen_market) { market_payload[4] }
    let(:external_id) { 'sr:match:1234:188' }

    it 'generates market external ID without specs' do
      create(:market_template, external_id: '188',
                               name: 'Template name')

      subject.call
      market = Market.find_by(external_id: external_id)
      expect(market).not_to be_nil
    end
  end
end
