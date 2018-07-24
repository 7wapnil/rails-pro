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
      found_event = service.send(:find_or_create_event!, event_id)

      expect(service).not_to have_received(:create_event)
      expect(found_event).to be_a(Event)
      expect(found_event.id).to eq(event.id)
    end

    it 'should query event data from API if not exists in db' do
      allow(service).to receive(:create_event)
      service.send(:find_or_create_event!, event_id)

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

    it 'should return market from db if exists' do
      event_id = 'sr:match:1234'
      event = create(:event, external_id: event_id)
      market = create(:market, event: event, external_id: "#{event_id}:47")

      found_market = service.send(:find_or_create_market!,
                                  event,
                                  markets_data[0])
      expect(found_market.id).to eq(market.id)
    end

    it 'should create market with specifiers if not exists' do
      event_id = 'sr:match:1234'
      external_id = "#{event_id}:47"
      event = create(:event, external_id: event_id)

      created_market = service.send(:find_or_create_market!,
                                    event,
                                    markets_data[0])
      expect(created_market.id).not_to be_nil
      expect(created_market.external_id).to eq(external_id)
    end
  end

  context 'odds' do
    let(:odds_data) { job['odds_change']['odds']['market'][0]['outcome'] }

    it 'should return odd from db if exists' do
      market = create(:market, external_id: 'market:id')
      odd_external_id = "#{market.external_id}:#{odds_data[0]['@id']}"
      create(:odd, market: market, external_id: odd_external_id)

      found_odd = service.send(:find_or_create_odd!, market, odds_data[0])
      expect(found_odd.id).not_to be_nil
      expect(found_odd.external_id).to eq(odd_external_id)
    end

    it 'should create odd if not exists' do
      market = create(:market, external_id: 'market:id')
      odd_external_id = "#{market.external_id}:#{odds_data[0]['@id']}"

      created_odd = service.send(:find_or_create_odd!, market, odds_data[0])
      expect(created_odd.id).not_to be_nil
      expect(created_odd.external_id).to eq(odd_external_id)
      expect(created_odd.value).to eq(1.12)
    end

    it 'should update odd value' do
      market = create(:market, external_id: 'market:id')
      odd_external_id = "#{market.external_id}:#{odds_data[0]['@id']}"
      create(:odd, market: market, external_id: odd_external_id, value: 99.99)

      found_odd = service.send(:find_or_create_odd!, market, odds_data[0])
      expect(found_odd.value).to eq(1.12)
    end
  end
end
