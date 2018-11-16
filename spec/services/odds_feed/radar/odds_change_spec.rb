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
    allow(subject).to receive(:generate_market!)
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

  describe '#create_or_find_event!' do
    it 'saves event retrieved from the API' do
      expect(event).to receive(:save!).and_return(true)
      subject.send(:create_or_find_event!)
    end

    context 'fails to save event because it already exists' do
      let!(:existing_event) do
        create(:event, title: build(:title), external_id: event_id)
      end

      it 'raises ActiveRecord::RecordInvalid on event save attempt' do
        expect(event).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        subject.send(:create_or_find_event!)
      end

      it 'finds existing event' do
        expect(Event)
          .to receive(:find_by!)
          .with(external_id: event_id)
          .and_return(existing_event)

        subject.send(:create_or_find_event!)
      end
    end
  end

  it 'updates event status from message' do
    create(:event, external_id: event_id, status: :not_started)
    subject.handle
    event = Event.find_by(external_id: event_id)
    expect(event.status).to eq('started')
  end

  it 'updates event end at time on "ended" status' do
    create(:event, external_id: event_id, status: :not_started)
    allow(subject).to receive(:event_status).and_return(Event.statuses[:ended])
    subject.handle
    event = Event.find_by(external_id: event_id)
    expect(event.status).to eq('ended')
    expect(event.end_at).not_to be_nil
  end

  it 'adds producer id to event payload' do
    payload_addition = {
      producer: { origin: :radar, id: payload['odds_change']['product'] },
      event_status:
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
      .with(WebSocket::Signals::EVENT_CREATED, id: created_event.id.to_s)
  end

  it 'calls for live coverage booking' do
    expect(Radar::LiveCoverageBookingWorker)
      .to receive(:perform_async)
      .with(event_id)

    subject.handle
  end

  it 'calls market generator for every market data row' do
    subject.handle
    expect(subject)
      .to have_received(:generate_market!)
      .exactly(5)
      .times
  end

  it 'skips single market generation on error' do
    allow(subject).to receive(:generate_market!).and_raise(StandardError)
    subject.handle
    expect(subject)
      .to have_received(:generate_market!)
      .exactly(5)
      .times
  end

  describe '#market data' do
    subject { OddsFeed::Radar::OddsChangeHandler.new(payload_single_market) }

    it 'calls market generator for single market' do
      subject.handle
      expect(subject)
        .to have_received(:generate_market!)
        .with(payload_single_market['odds_change']['odds']['market'])
        .once
    end

    context 'event_data odds empty' do
      let(:payload) do
        payload_single_market.tap do |payload|
          payload['odds_change']['odds'] = []
        end
      end
      subject { OddsFeed::Radar::OddsChangeHandler.new(payload) }

      it 'does not generate markets' do
        expect(subject).to_not have_received(:generate_market!)
      end
    end

    context 'markets_data prepared for one markets_payload' do
      let(:payload) do
        payload_single_market.tap do |payload|
          payload['odds_change']['odds']['market'] = {
            id: 124,
            specifiers: 'set=2|game=3|point=1',
            status: -1,
            outcome: [ {id: 1, odds: 1.3, active: 1}]
          }
        end
      end
      subject { OddsFeed::Radar::OddsChangeHandler.new(payload) }

      before { subject.handle }

      it 'calls generate markets once' do
        expect(subject).to have_received(:generate_market!).once
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
              outcome: [ {id: 1, odds: 1.3, active: 1}]
            },
            {
              id: 125,
              specifiers: 'set=2|game=3|point=1',
              status: -1,
              outcome: [ {id: 2, odds: 1.3, active: 1}]
            }
          ]
        end
      end
      subject { OddsFeed::Radar::OddsChangeHandler.new(payload) }

      before { subject.handle }

      it 'calls generate markets once' do
        expect(subject).to have_received(:generate_market!).twice
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
        expect(subject).not_to have_received(:generate_market!)
      end
    end
  end
end
