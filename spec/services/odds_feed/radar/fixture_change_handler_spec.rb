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
        'product' => liveodds_producer.id.to_s
      }
    }
  end

  let(:event_id)  { payload['fixture_change']['event_id'] }
  let(:api_event) { build(:event, producer: prematch_producer) }

  let(:payload_update) { { producer: { origin: :radar, id: '1' } } }

  before do
    allow(subject_api).to receive(:api_event) { api_event }
  end

  context 'new event' do
    after { subject_api.handle }

    it 'logs event create message' do
      expect(subject_api).to receive(:log_on_create)
    end

    it 'sets producer' do
      expect(subject_api)
        .to receive(:update_event_producer!).with(liveodds_producer)
    end

    it 'does not call live coverage booking, moved to Radar CTRL' do
      expect(Radar::LiveCoverageBookingWorker)
        .not_to receive(:perform_async)
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
    after { subject_api.handle }

    let(:event) { create(:event, external_id: event_id, active: true) }

    before do
      allow(subject_api).to receive(:event) { event }
    end

    it 'calls #update_from! on found event' do
      expect(event).to receive(:update_from!).with(api_event)
    end

    it 'logs event update message' do
      expect(subject_api).to receive(:log_on_update)
    end

    it 'updates producer info' do
      expect(subject_api)
        .to receive(:update_event_producer!).with(liveodds_producer)
    end

    context 'cancelled event' do
      let(:payload) do
        {
          'fixture_change' => {
            'event_id' => external_event_id,
            'change_type' => '3',
            'product' => liveodds_producer.id.to_s
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
            'product' => liveodds_producer.id.to_s
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
