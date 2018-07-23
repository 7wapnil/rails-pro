describe OddsFeed::Service do
  let(:job) do
    Nori.new.parse(file_fixture('odds_change_message.xml').read)
  end
  let(:client) { OddsFeed::Radar::Client.new }
  let!(:service) { OddsFeed::Service.new(client, job) }

  context 'event' do
    let(:event_id) { job['odds_change']['@event_id'] }

    it 'should return event from db if exists' do
      allow(service).to receive(:create_event)
      event = create(:event, external_id: event_id)
      found_event = service.send(:event, event_id)

      expect(service).not_to have_received(:create_event)
      expect(found_event).to be_a(Event)
      expect(found_event.id).to eq(event.id)
    end

    it 'should query event data from API if not exists in db' do
      allow(service).to receive(:create_event)
      service.send(:event, event_id)

      expect(service)
        .to have_received(:create_event)
        .with(event_id)
    end

    it 'should store event in db from API request data' do
      payload = Nori.new.parse(file_fixture('radar_event_fixture.xml').read)
      adapter = OddsFeed::Radar::EventAdapter.new(payload)
      allow(client).to receive(:event).and_return(adapter)

      external_id = payload['fixtures_fixture']['fixture']['@id']

      result = service.send(:create_event, external_id)
      expect(result).to be_a(Event)
      expect(result.id).not_to be_nil
      expect(result.external_id).to eq(external_id)
      expect(Title.find(result.title.id)).not_to be_nil
    end
  end

  context 'markets' do
    let(:markets_data) { job['odds_change']['odds']['market'] }

    it 'should generate market external id by template id and specifiers' do
      allow(service).to receive(:market)

      [
        [{ "@id": '47',
           "@specifiers": 'score=47' }, '47:score=47'],
        [{ "@id": '1001',
           "@specifiers": 'set=2|game=3|point=1' },
         '1001:set=2|game=3|point=1'],
        [{ "@id": '10000' }, '10000']
      ].each do |data, expected|
        expect(service.send(:market_id, data.stringify_keys)).to eq(expected)
      end
    end

    it 'should return market from db if exists' do
      external_id = '47:score=41.5'
      event = create(:event)
      market = create(:market, event: event, external_id: external_id)

      found_market = service.send(:market, event, markets_data[0])
      expect(found_market.id).to eq(market.id)
    end

    it 'should create market with specifiers if not exists' do
      external_id = '47:score=41.5'
      event = create(:event)

      created_market = service.send(:market, event, markets_data[0])
      expect(created_market.id).not_to be_nil
      expect(created_market.external_id).to eq(external_id)
    end
  end
end
