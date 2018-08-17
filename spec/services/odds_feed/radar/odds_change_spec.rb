describe OddsFeed::Radar::OddsChangeHandler do
  let(:payload) do
    XmlParser.parse(file_fixture('odds_change_message.xml').read)
  end
  let(:event_id) { payload['odds_change']['event_id'] }
  let(:event) { build(:event, title: build(:title), external_id: event_id) }
  let!(:timestamp) { Time.now + 60 }

  subject { OddsFeed::Radar::OddsChangeHandler.new(payload) }

  before do
    allow(subject).to receive(:generate_market!)
    allow(subject).to receive(:timestamp).and_return(timestamp)
    allow(subject).to receive(:request_event).and_return(event)
  end

  it 'requests event data from API if not found in db' do
    subject.handle
    expect(subject)
      .to have_received(:request_event).with(event_id)
  end

  it 'does not request API if event exists in db' do
    create(:event, external_id: event_id)
    allow(subject).to receive(:create_event)
    subject.handle
    expect(subject).not_to have_received(:create_event)
  end

  it 'raises InvalidMessageError if message is late' do
    create(:event, external_id: event_id, updated_at: Time.now + 300)
    expect { subject.handle }.to raise_error(OddsFeed::InvalidMessageError)
  end

  it 'sends websocket message when new event created' do
    subject.handle

    created_event = Event.find_by!(external_id: event_id)
    expect(WebSocket::Client.instance)
      .to have_received(:emit)
      .with(WebSocket::Signals::UPDATE_EVENT,
            id: created_event.id.to_s,
            name: created_event.name,
            start_at: event.start_at)
  end

  it 'calls market generator for every market data row' do
    subject.handle
    expect(subject)
      .to have_received(:generate_market!)
      .exactly(5)
      .times
  end
end
