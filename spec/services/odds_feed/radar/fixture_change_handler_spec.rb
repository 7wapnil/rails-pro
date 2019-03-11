# frozen_string_literal: true

describe OddsFeed::Radar::FixtureChangeHandler do
  let(:subject_api) { described_class.new(payload) }

  let(:liveodds_producer) { create(:liveodds_producer) }
  let(:prematch_producer) { create(:prematch_producer) }

  let(:external_event_id) { 'sr:match:1234' }

  let(:payload) do
    {
      'fixture_change' => {
        'event_id' => external_event_id,
        'change_type' => '4',
        'product' => prematch_producer.id.to_s
      }
    }
  end

  let(:event_id) { payload['fixture_change']['event_id'] }

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
  let(:api_event) do
    build(:event, producer: liveodds_producer, payload: event_payload)
  end

  let(:payload_update) { { producer: { origin: :radar, id: '1' } } }

  before do
    allow(subject_api).to receive(:api_event) { api_event }
  end

  context 'new event' do
    it_behaves_like 'service caches competitors and players' do
      let(:event_payload) do
        {
          competitors: {
            competitor: [event_competitor_payload]
          }
        }.deep_stringify_keys
      end
      let(:service_call) { subject_api.handle }

      it 'calls CompetitorLoader' do
        expect(OddsFeed::Radar::Entities::CompetitorLoader)
          .to have_received(:call)
          .with(external_id: competitor_id)
      end
    end

    it 'logs event create message' do
      expect(subject_api).to receive(:log_on_create)

      subject_api.handle
    end

    it 'sets producer' do
      expect(subject_api)
        .to receive(:update_event_producer!)
        .with(prematch_producer)

      subject_api.handle
    end

    it 'creates event' do
      expect { subject_api.handle }.to change(Event, :count).by(1)
    end

    context 'with liveodds producer' do
      let(:payload) do
        {
          'fixture_change' => {
            'event_id' => external_event_id,
            'change_type' => '4',
            'product' => liveodds_producer.id.to_s
          }
        }
      end

      it 'does not create event' do
        expect { subject_api.handle }.not_to change(Event, :count)
      end
    end
  end

  context 'returns empty event from Radar API' do
    let(:api_event) { Event.new }

    it 'and raises an error' do
      expect { subject_api.handle }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'events are updating simultaneously' do
    context 'and have same event scopes' do
      let(:control_count) { rand(2..4) }
      let(:event_scopes)  { create_list(:event_scope, control_count) }
      let(:scoped_events) do
        event_scopes.map { |scope| ScopedEvent.new(event_scope: scope) }
      end

      let(:api_event) do
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
        expect(api_event.scoped_events.count).to eq(control_count)
      end
    end
  end

  context 'existing event' do
    let(:event) do
      create(:event,
             external_id: event_id,
             active: true,
             payload: event_payload)
    end

    before do
      allow(subject_api).to receive(:event) { event }
    end

    after { subject_api.handle }

    it_behaves_like 'service caches competitors and players' do
      let(:event_payload) do
        {
          competitors: {
            competitor: [event_competitor_payload]
          }
        }.deep_stringify_keys
      end
      let(:service_call) { subject_api.handle }

      it 'calls CompetitorLoader' do
        expect(OddsFeed::Radar::Entities::CompetitorLoader)
          .to have_received(:call)
          .with(external_id: competitor_id)
      end
    end

    it 'calls #update_from! on found event' do
      expect(event).to receive(:update_from!).with(api_event)
    end

    it 'logs event update message' do
      expect(subject_api).to receive(:log_on_update)
    end

    it 'updates producer info' do
      expect(subject_api)
        .to receive(:update_event_producer!).with(prematch_producer)
    end

    context 'cancelled event' do
      let(:payload) do
        {
          'fixture_change' => {
            'event_id' => external_event_id,
            'change_type' => '3',
            'product' => prematch_producer.id.to_s
          }
        }
      end

      it 'sets event activity status to inactive' do
        subject_api.handle
        expect(Event.find_by!(external_id: external_event_id).active)
          .to be_falsy
      end
    end

    context 'producer change' do
      let(:payload) do
        {
          'fixture_change' => {
            'event_id' => external_event_id,
            'change_type' => '3',
            'product' => prematch_producer.id.to_s
          }
        }
      end

      it 'updates producer info' do
        expect(subject_api)
          .to receive(:update_event_producer!).with(prematch_producer)
      end
    end

    context 'cancelled event' do
      let(:payload) do
        {
          'fixture_change' => {
            'event_id' => external_event_id,
            'change_type' => '3',
            'product' => prematch_producer.id.to_s
          }
        }
      end

      it 'sets event activity status to inactive' do
        subject_api.handle
        expect(Event.find_by!(external_id: external_event_id).active)
          .to be_falsy
      end
    end

    context 'on unsupported external id' do
      subject { described_class.new(payload) }

      before { payload['fixture_change']['event_id'] = 'sr:season:1234' }

      it 'does nothing' do
        expect_any_instance_of(Event).not_to receive(:save!)
        subject_api.handle
      end
    end
  end
end
