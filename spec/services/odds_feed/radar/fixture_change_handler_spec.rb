describe OddsFeed::Radar::FixtureChangeHandler do
  subject { described_class.new(payload) }

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

  let(:api_event) { build(:event, producer: prematch_producer) }

  before do
    allow(subject_api).to receive(:api_event) { api_event }
  end

  after do
    subject_api.handle
  end

  context 'new event' do
    it 'logs event create message' do
      expect(subject_api).to receive(:log_on_create)
    end

    it 'sets producer' do
      expect(subject_api)
        .to receive(:update_event_producer!).with(liveodds_producer)
    end

    it 'calls for live coverage booking' do
      expect(Radar::LiveCoverageBookingWorker)
        .to receive(:perform_async)
        .with(api_event.external_id)
    end
  end

  context 'existing event' do
    let(:event) do
      create(:event,
             external_id: payload['fixture_change']['event_id'],
             active: true)
    end

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
        expect(Event.find_by!(external_id: external_event_id).active).to be_falsy
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
        expect(Event.find_by!(external_id: external_event_id).active).to be_falsy
      end
    end
  end
end
