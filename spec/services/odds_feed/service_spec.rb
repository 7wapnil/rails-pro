describe OddsFeed::Service do
  context 'event' do
    let(:job) do
      Nori.new.parse(file_fixture('odds_change_message.xml').read)
    end
    let(:event_id) { job['odds_change']['@event_id'] }
    let!(:client) do
      client = OddsFeed::Radar::Client.new
      allow(client).to receive(:event).and_return(Event.new)
      client
    end

    it 'should return event from db is exists' do
      service = OddsFeed::Service.new(client, job)
      event = service.event(event_id)

      expect(client)
        .to have_received(:event).with(event_id)
      expect(event).to be_a(Event)
    end

    it 'should query event data from API if not exists in db' do
      create(:event, external_id: event_id)

      service = OddsFeed::Service.new(client, job)
      event = service.event(event_id)

      expect(client).not_to have_received(:event)
      expect(event).to be_a(Event)
    end
  end
end
