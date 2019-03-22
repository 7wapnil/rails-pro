# frozen_string_literal: true

describe OddsFeed::Radar::OddsChangeHandler do
  subject { described_class.new(payload) }

  let(:profiler) { OddsFeed::MessageProfiler.enqueue }

  let(:subject_api) { described_class.new(payload, profiler) }

  let!(:producer_from_xml) { create(:producer, id: 2) }
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

  let(:competitor_payload) do
    XmlParser
      .parse(file_fixture('radar_team_sport_competitor_profile.xml').read)
  end

  let(:competitor_id) do
    competitor_payload.dig('competitor_profile', 'competitor', 'id')
  end

  let(:competitor_name) do
    competitor_payload.dig('competitor_profile', 'competitor', 'name')
  end

  let(:event_competitor_payload) do
    {
      id: competitor_id,
      name: competitor_name
    }.stringify_keys
  end

  let(:event_payload) {}
  let(:event) do
    build(:event,
          title: build(:title),
          external_id: event_id,
          payload: event_payload)
  end
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

    allow(WebSocket::Client.instance).to receive(:trigger_event_update)
    allow(WebSocket::Client.instance).to receive(:trigger_market_update)

    allow(subject_api).to receive(:call_markets_generator).and_return(timestamp)
    allow(subject_api).to receive(:timestamp).and_return(timestamp)
    allow(subject_api).to receive(:api_event).and_return(event)
    allow(OddsFeed::Radar::Entities::PlayerLoader)
      .to receive(:call)
      .and_return(Faker::Name.name)
  end

  it 'requests event data from API if not found in db' do
    subject_api.handle
    expect(subject_api).to have_received(:api_event)
  end

  it 'does not request API if event exists in db' do
    create(:event, external_id: event_id)
    allow(subject_api).to receive(:create_event)
    subject_api.handle
    expect(subject_api).not_to have_received(:create_event)
  end

  it 'updates event status from message' do
    create(:event, external_id: event_id, status: Event::NOT_STARTED)
    subject_api.handle
    event = Event.find_by(external_id: event_id)
    expect(event.status).to eq(Event::STARTED)
  end

  it_behaves_like 'service caches competitors and players' do
    let(:event_payload) do
      {
        competitors: {
          competitor: [event_competitor_payload]
        }
      }.deep_stringify_keys
    end
    let(:service_call) { subject_api.handle }

    it 'calls EventBasedCache::Writer' do
      expect(OddsFeed::Radar::EventBasedCache::Writer)
        .to have_received(:call)
        .with(event: event)
    end
  end

  context 'events are updating simultaneously' do
    context 'and have same event scopes' do
      let(:control_count) { rand(2..4) }
      let(:event_scopes)  { create_list(:event_scope, control_count) }
      let(:scoped_events) do
        event_scopes.map { |scope| ScopedEvent.new(event_scope: scope) }
      end

      let(:event) do
        build(:event, title:         build(:title),
                      external_id:   event_id,
                      scoped_events: scoped_events)
      end

      before do
        create(:event, title:        build(:title),
                       external_id:  event_id,
                       event_scopes: event_scopes)

        allow(Event).to receive(:find_by).with(external_id: event_id)
      end

      it "don't cause ActiveRecord::RecordNotUnique error" do
        expect(scoped_events)
          .to all(
            receive(:update!).and_raise(ActiveRecord::RecordNotUnique)
          )

        subject_api.handle
      end

      it "don't produce duplicates" do
        subject_api.handle
        expect(event.scoped_events.count).to eq(control_count)
      end
    end
  end

  context 'event activity' do
    let(:positive_status) { Event::NOT_STARTED }
    let(:event_to_be_marked_as_active) do
      create(
        :event_with_odds,
        external_id: event_id,
        status: positive_status,
        active: false
      )
        .tap do |event|
          event_market = event.markets.sample
          event_market.update(status: Market::ACTIVE)
          event_market.odds.sample.update(status: Odd::ACTIVE)
        end
    end
    let(:profiler) { OddsFeed::MessageProfiler.enqueue }

    it 'defines event as active' do
      event_to_be_marked_as_active
      described_class.new(payload, profiler).handle
      event = Event.find_by(external_id: event_id)
      expect(event.active).to be_truthy
    end

    it 'defines event as inactive when no active outcomes' do
      create(:event,
             external_id: event_id,
             status: Event::NOT_STARTED,
             active: true)

      described_class.new(payload_inactive_outcomes, profiler).handle
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

        described_class.new(payload, profiler).handle
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
      subject_api.handle
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

  context 'with persisted event' do
    before { event.save! }

    let(:payload_addition_to_event) do
      {
        state:
          {
            id: event.id * 1000,
            status_code: '1',
            status: '1st period',
            score: '2:0',
            time: '10:00',
            period_scores: [],
            finished: false
          }
      }
    end

    it 'applies correct diff to event' do
      allow(Event).to receive(:find_by) { event }
      allow(event)
        .to receive(:add_to_payload).and_call_original

      subject_api.handle

      expect(event)
        .to have_received(:add_to_payload)
        .with(payload_addition_to_event).once
    end

    context 'with competitor payload' do
      before do
        allow(OddsFeed::Radar::Entities::CompetitorLoader).to receive(:call)
        subject_api.handle
      end

      it 'does not call CompetitorLoader' do
        expect(OddsFeed::Radar::Entities::CompetitorLoader)
          .not_to have_received(:call)
      end
    end
  end

  it 'changes event producer' do
    subject_api.handle

    expect(event.producer).to eq(producer_from_xml)
  end

  #TODO: Unxit
  xit 'sends websocket message when new event created' do
    subject_api.handle

    created_event = Event.find_by!(external_id: event_id)
    expect(WebSocket::Client.instance)
      .to have_received(:trigger_event_update)
      .with(created_event)
      .twice
  end

  context 'empty payload' do
    context 'is nil' do
      let(:payload)  {}
      let(:event_id) {}

      it 'logs failure' do
        expect(subject_api).to receive(:log_job_failure)
        subject_api.handle
      end

      it 'is not processed' do
        expect(subject_api.handle).to be_nil
      end
    end

    context 'with odds_change missing' do
      before { payload.delete('odds_change') }

      it 'logs failure' do
        expect(subject_api).to receive(:log_job_failure)
        subject_api.handle
      end

      it 'is not processed' do
        expect(subject_api.handle).to be_nil
      end
    end

    context 'with sport_event_status missing totally' do
      before { payload['odds_change'].delete('sport_event_status') }

      it 'event status is set as NOT_STARTED' do
        expect(subject_api.handle.status).to eq(Event::NOT_STARTED)
      end
    end

    context 'with sport_event_status missing status key' do
      before do
        payload['odds_change']['sport_event_status'].delete('status')
      end

      it 'event status is set as NOT_STARTED' do
        expect(subject_api.handle.status).to eq(Event::NOT_STARTED)
      end
    end
  end

  describe '#market data' do
    subject { described_class.new(payload_single_market) }

    context 'input_data odds empty' do
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

      before do
        allow(subject_api)
          .to receive(:call_markets_generator)
          .and_call_original
        allow(::OddsFeed::Radar::MarketGenerator::Service)
          .to receive(:call)

        subject_api.handle
      end

      let(:payload) { payload_single_market }

      it 'calls generate markets' do
        expect(::OddsFeed::Radar::MarketGenerator::Service)
          .to have_received(:call)
          .with(
            event,
            [payload['odds_change']['odds']['market']],
            instance_of(Hash)
          )
          .once
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

      before do
        allow(subject_api)
          .to receive(:call_markets_generator)
          .and_call_original
        allow(OddsFeed::Radar::MarketGenerator::Service)
          .to receive(:call)
          .and_call_original

        event.save!
        subject_api.handle
      end

      it 'calls generate markets' do
        expect(OddsFeed::Radar::MarketGenerator::Service)
          .to have_received(:call)
          .with(
            event,
            instance_of(Array),
            instance_of(Hash)
          )
          .once
      end
    end

    context 'markets_data prepared for wrong markets_payload' do
      subject { described_class.new(payload) }

      let(:payload) do
        payload_single_market.tap do |payload|
          payload['odds_change']['odds']['market'] = 'wrong'
        end
      end

      before do
        allow(subject_api)
          .to receive(:call_markets_generator)
          .and_call_original
        subject_api.handle
      end

      it 'does not generate markets' do
        expect(subject_api).not_to have_received(:call_markets_generator)
      end
    end

    context 'empty event returns from Radar API' do
      subject { described_class.new(payload) }

      let(:event) { Event.new }

      it 'and raise an error' do
        expect { subject_api.handle }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'on unsupported external id' do
      subject { described_class.new(payload) }

      before { payload['odds_change']['event_id'] = 'sr:season:1234' }

      it 'does nothing' do
        expect_any_instance_of(Event).not_to receive(:save!)
        subject_api.handle
      end
    end
  end
end
