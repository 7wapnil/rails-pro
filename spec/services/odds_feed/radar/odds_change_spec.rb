describe OddsFeed::Radar::OddsChangeHandler do
  let(:payload) do
    XmlParser.parse(file_fixture('odds_change_message.xml').read)
  end
  let(:payload_single_market) do
    XmlParser.parse(file_fixture('odds_change_with_single_market.xml').read)
  end
  let(:event_id) { payload['odds_change']['event_id'] }
  let(:event) { build(:event, title: build(:title), external_id: event_id) }
  let!(:timestamp) { Time.now + 60 }

  subject { OddsFeed::Radar::OddsChangeHandler.new(payload) }

  before do
    allow(subject).to receive(:call_markets_generator).and_return(timestamp)
    allow(subject).to receive(:timestamp).and_return(timestamp)
    allow(subject).to receive(:api_event).and_return(event)
  end

  it 'requests event data from API if not found in db' do
    subject.handle
    expect(subject).to have_received(:api_event)
  end

  it 'does not request API if event exists in db' do
    create(:event, external_id: event_id)
    allow(subject).to receive(:create_or_find_event!)
    subject.handle
    expect(subject).not_to have_received(:create_or_find_event!)
  end

  it 'updates event status from message' do
    create(:event, external_id: event_id, status: Event::NOT_STARTED)
    subject.handle
    event = Event.find_by(external_id: event_id)
    expect(event.status).to eq(Event::STARTED)
  end

  it 'updates event end at time on "ended" status' do
    create(:event, external_id: event_id, status: Event::NOT_STARTED)
    allow(subject).to receive(:event_status).and_return(Event::ENDED)
    subject.handle
    event = Event.find_by(external_id: event_id)
    expect(event.status).to eq(Event::ENDED)
    expect(event.end_at).not_to be_nil
  end

  context 'updates to status that is not mentioned in docs' do
    let(:found_event) { Event.find_by(external_id: event_id).reload }
    let(:status)      {}

    before do
      payload['odds_change']['sport_event_status']['status'] = status
      subject.handle
    end

    context 'abandoned' do
      let(:status) { '9' }

      it { expect(found_event.status).to eq(Event::ABANDONED) }
    end

    context 'suspended' do
      let(:status) { '2' }

      it { expect(found_event.status).to eq(Event::SUSPENDED) }
    end
  end

  it 'adds producer id to event payload' do
    payload_addition = {
      producer: { origin: :radar, id: payload['odds_change']['product'] },
      state:
        OddsFeed::Radar::EventStatusService.new.call(
          event_id: event.id,
          data: payload['odds_change']['sport_event_status']
        )
    }

    allow(Event).to receive(:find_by) { event }

    expect(event)
      .to receive(:add_to_payload)
      .with(payload_addition)

    subject.handle
  end

  it 'sends websocket message when new event created' do
    subject.handle

    created_event = Event.find_by!(external_id: event_id)
    expect(WebSocket::Client.instance)
      .to have_received(:emit)
      .with(WebSocket::Signals::EVENT_UPDATED, id: created_event.id.to_s)
  end

  it 'calls for live coverage booking' do
    expect(Radar::LiveCoverageBookingWorker)
      .to receive(:perform_async)
      .with(event_id)

    subject.handle
  end

  describe '#market data' do
    subject { OddsFeed::Radar::OddsChangeHandler.new(payload_single_market) }

    context 'event_data odds empty' do
      let(:payload) do
        payload_single_market.tap do |payload|
          payload['odds_change']['odds'] = []
        end
      end
      subject { OddsFeed::Radar::OddsChangeHandler.new(payload) }

      it 'does not generate markets' do
        expect(subject).to_not have_received(:call_markets_generator)
      end
    end

    context 'markets_data prepared for one markets_payload' do
      let(:payload) do
        payload_single_market.tap do |payload|
          payload['odds_change']['odds']['market'] = {
            id: 124,
            specifiers: 'set=2|game=3|point=1',
            status: -1,
            outcome: [{ id: 1, odds: 1.3, active: 1 }]
          }
        end
      end
      subject { OddsFeed::Radar::OddsChangeHandler.new(payload) }

      before { subject.handle }

      it 'calls generate markets' do
        expect(subject).to have_received(:call_markets_generator)
      end
    end

    context 'markets_data prepared for multiple markets_payload' do
      let(:payload) do
        payload_single_market.tap do |payload|
          payload['odds_change']['odds']['market'] = [
            {
              id: 124,
              specifiers: 'set=2|game=3|point=1',
              status: -1,
              outcome: [{ id: 1, odds: 1.3, active: 1 }]
            },
            {
              id: 125,
              specifiers: 'set=2|game=3|point=1',
              status: -1,
              outcome: [{ id: 2, odds: 1.3, active: 1 }]
            }
          ]
        end
      end
      subject { OddsFeed::Radar::OddsChangeHandler.new(payload) }

      before { subject.handle }

      it 'calls generate markets' do
        expect(subject).to have_received(:call_markets_generator)
      end
    end

    context 'markets_data prepared for wrong markets_payload' do
      let(:payload) do
        payload_single_market.tap do |payload|
          payload['odds_change']['odds']['market'] = 'wrong'
        end
      end
      subject { OddsFeed::Radar::OddsChangeHandler.new(payload) }

      before { subject.handle }

      it 'does not generate markets' do
        expect(subject).not_to have_received(:call_markets_generator)
      end
    end
  end
end
