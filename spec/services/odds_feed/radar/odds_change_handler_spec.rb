describe OddsFeed::Radar::OddsChangeHandler do
  subject { described_class.new(payload) }

  let(:subject_api) { described_class.new(payload) }

  let(:payload) do
    XmlParser.parse(file_fixture('odds_change_message.xml').read)
  end
  let(:payload_single_market) do
    XmlParser.parse(file_fixture('odds_change_with_single_market.xml').read)
  end
  let(:payload_inactive_outcomes) do
    XmlParser.parse(file_fixture('odds_change_with_inactive_outcomes.xml').read)
  end
  let(:event_id) { payload['odds_change']['event_id'] }
  let(:event) { build(:event, title: build(:title), external_id: event_id) }
  let!(:timestamp) { Time.now + 60 }

  before do
    payload = {
      outcomes: {
        outcome: [
          { 'id': '1', name: 'Odd 1 name' },
          { 'id': '2', name: 'Odd 2 name' }
        ]
      }
    }.deep_stringify_keys

    create(:market_template, external_id: '47',
                             name: 'Template name',
                             payload: payload)
    create(:market_template, external_id: '48',
                             name: 'Template name',
                             payload: payload)
    create(:market_template, external_id: '49',
                             name: 'Template name',
                             payload: payload)
    create(:market_template, external_id: '188',
                             name: 'Template name')

    allow(subject_api).to receive(:call_markets_generator).and_return(timestamp)
    allow(subject_api).to receive(:timestamp).and_return(timestamp)
    allow(subject_api).to receive(:api_event).and_return(event)
  end

  it 'requests event data from API if not found in db' do
    subject_api.handle
    expect(subject_api).to have_received(:api_event)
  end

  it 'does not request API if event exists in db' do
    create(:event, external_id: event_id)
    allow(subject_api).to receive(:create_or_find_event!)
    subject_api.handle
    expect(subject_api).not_to have_received(:create_or_find_event!)
  end

  it 'updates event status from message' do
    create(:event, external_id: event_id, status: Event::NOT_STARTED)
    subject_api.handle
    event = Event.find_by(external_id: event_id)
    expect(event.status).to eq(Event::STARTED)
  end

  context 'event activity' do
    it 'defines event as active' do
      create(:event,
             external_id: event_id,
             status: Event::NOT_STARTED,
             active: false)

      described_class.new(payload).handle
      event = Event.find_by(external_id: event_id)
      expect(event.active).to be_truthy
    end

    it 'defines event as inactive when no active outcomes' do
      create(:event,
             external_id: event_id,
             status: Event::NOT_STARTED,
             active: true)

      described_class.new(payload_inactive_outcomes).handle
      event = Event.find_by(external_id: event_id)
      expect(event.active).to be_falsy
    end

    %w[3 4 5 9].each do |radar_status|
      it "defines event as inactive when receive status '#{radar_status}'" do
        payload['odds_change']['sport_event_status']['status'] = radar_status

        create(:event,
               external_id: event_id,
               status: Event::NOT_STARTED,
               active: true)

        described_class.new(payload).handle
        event = Event.find_by(external_id: event_id)
        expect(event.active).to be_falsy
      end
    end
  end

  it 'updates event end at time on "ended" status' do
    create(:event, external_id: event_id, status: Event::NOT_STARTED)
    allow(subject_api).to receive(:event_status).and_return(Event::ENDED)
    subject_api.handle
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

    subject_api.handle
  end

  it 'sends websocket message when new event created' do
    subject_api.handle

    created_event = Event.find_by!(external_id: event_id)
    expect(WebSocket::Client.instance)
      .to have_received(:emit)
      .with(WebSocket::Signals::EVENT_UPDATED, id: created_event.id.to_s)
  end

  it 'calls for live coverage booking' do
    expect(Radar::LiveCoverageBookingWorker)
      .to receive(:perform_async)
      .with(event_id)

    subject_api.handle
  end

  describe '#market data' do
    subject { described_class.new(payload_single_market) }

    context 'event_data odds empty' do
      subject { described_class.new(payload) }

      let(:payload) do
        payload_single_market.tap do |payload|
          payload['odds_change']['odds'] = []
        end
      end

      it 'does not generate markets' do
        expect(
          subject_api
        ).not_to have_received(:call_markets_generator)
      end
    end

    context 'markets_data prepared for one markets_payload' do
      subject { described_class.new(payload) }

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

      before { subject_api.handle }

      it 'calls generate markets' do
        expect(subject_api).to have_received(:call_markets_generator)
      end
    end

    context 'markets_data prepared for multiple markets_payload' do
      subject { described_class.new(payload) }

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

      before { subject_api.handle }

      it 'calls generate markets' do
        expect(subject_api).to have_received(:call_markets_generator)
      end
    end

    context 'markets_data prepared for wrong markets_payload' do
      subject { described_class.new(payload) }

      let(:payload) do
        payload_single_market.tap do |payload|
          payload['odds_change']['odds']['market'] = 'wrong'
        end
      end

      before { subject_api.handle }

      it 'does not generate markets' do
        expect(subject_api).not_to have_received(:call_markets_generator)
      end
    end
  end
end
