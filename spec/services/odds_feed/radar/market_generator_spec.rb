describe OddsFeed::Radar::MarketGenerator do
  let(:market_payload) do
    data = XmlParser.parse(file_fixture('odds_change_message.xml').read)
    data['odds_change']['odds']['market']
  end
  let(:chosen_market) { nil }
  let(:event) { create(:event, external_id: 'sr:match:1234') }
  let(:transpiler) { OddsFeed::Radar::Transpiler.new(event, '123') }

  subject { OddsFeed::Radar::MarketGenerator.new(event, chosen_market) }

  before do
    allow(transpiler).to receive(:transpile).and_return('transpiler value')
    allow(subject).to receive(:transpiler).and_return(transpiler)

    payload = {
      outcomes: {
        outcome: [
          { 'id': '1' },
          { 'id': '2' }
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
      subject.generate
      market = Market.find_by(external_id: external_id)
      expect(market).not_to be_nil
    end

    it 'generates new market with default priority' do
      subject.generate
      market = Market.find_by(external_id: external_id)
      expect(market.priority).to eq(0)
    end

    it 'sends websocket message on new market creation' do
      subject.generate
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
      subject.generate
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

      subject.generate
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
        subject.generate
        market = Market.find_by(external_id: external_id)
        expect(market.status).to eq(expectation[:result])
      end
    end

    context 'odds' do
      it 'creates odds if not exist in db' do
        subject.generate
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

        subject.generate
        expect(Odd.find_by(external_id: "#{external_id}:1").value).to eq(1.3)
        expect(Odd.find_by(external_id: "#{external_id}:2").value).to eq(1.7)
      end

      it 'skips single odd handling on error' do
        allow(subject).to receive(:generate_odd!).and_raise(StandardError)
        subject.generate
        expect(subject)
          .to have_received(:generate_odd!)
          .exactly(2)
          .times
      end

      it 'sends websocket message on new odd creation' do
        subject.generate

        odd = Odd.find_by!(external_id: "#{external_id}:1")
        expect(WebSocket::Client.instance)
          .to have_received(:emit)
          .with(WebSocket::Signals::ODD_CREATED,
                id: odd.id.to_s,
                marketId: odd.market.id.to_s,
                eventId: odd.market.event.id.to_s)
      end

      describe '#generate_odd!' do
        let(:market) do
          create(
            :market,
            external_id: external_id,
            event: event,
            status: :active
          )
        end

        let(:odd_data) do
          { 'id' => '1', 'active' => '1', 'odds' => '1.85' }
        end

        it 'retries to find the odd if fails to save the duplicate' do
          odd_payload = { external_id: "#{external_id}:1", market: market }

          existing_odd = create(:odd, odd_payload)
          initialized_odd = build(:odd, odd_payload)

          allow(Odd)
            .to receive(:find_or_initialize_by)
            .and_return(initialized_odd, existing_odd)

          expect(initialized_odd)
            .to receive(:save!)
            .and_raise(ActiveRecord::RecordInvalid)

          expect(existing_odd)
            .to receive(:save!)
            .and_return(true)

          subject.send(:generate_odd!, odd_data)
        end
      end
    end
  end

  context 'market without specifiers' do
    let(:chosen_market) { market_payload[4] }
    let(:external_id) { 'sr:match:1234:188' }

    it 'generates market external ID without specs' do
      allow(subject).to receive(:generate_odds!)
      subject.generate
      market = Market.find_by(external_id: external_id)
      expect(market).not_to be_nil
    end
  end
end
