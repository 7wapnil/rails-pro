describe OddsFeed::Radar::FixtureChangeHandler do
  let(:subject_api) { described_class.new(payload) }

  let(:payload) do
    {
      'fixture_change' => {
        'event_id' => 'sr:match:1234',
        'change_type' => '4',
        'product' => '1'
      }
    }
  end

  let(:api_event) { build(:event) }

  let(:payload_update) { { producer: { origin: :radar, id: '1' } } }

  before do
    allow(subject_api).to receive(:api_event) { api_event }
  end

  context 'new event' do
    after { subject_api.handle }

    it 'logs event create message' do
      expect(subject_api).to receive(:log_on_create)
    end

    it 'adds producer info to payload' do
      expect(api_event).to receive(:add_to_payload).with(payload_update)
    end

    it 'calls for live coverage booking' do
      expect(Radar::LiveCoverageBookingWorker)
        .to receive(:perform_async)
        .with(api_event.external_id)
    end
  end

  context 'returns empty event from Radar API' do
    let(:api_event) { Event.new }

    it 'and raises an error' do
      expect { subject_api.handle }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'existing event' do
    after { subject_api.handle }

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

    it 'adds producer info to payload' do
      # Event receives :add_to_payload twice,
      # this test checks arguments for second call
      expect(event).to receive(:add_to_payload)
      expect(event).to receive(:add_to_payload).with(payload_update)
    end

    context 'cancelled event' do
      let(:payload) do
        {
          'fixture_change' => {
            'event_id' => 'sr:match:1234',
            'change_type' => '3',
            'product' => '1'
          }
        }
      end

      it 'sets event activity status to inactive' do
        subject_api.handle
        expect(Event.find_by!(external_id: 'sr:match:1234').active).to be_falsy
      end
    end

    context 'cancelled event' do
      let(:payload) do
        {
          'fixture_change' => {
            'event_id' => 'sr:match:1234',
            'change_type' => '3',
            'product' => '1'
          }
        }
      end

      it 'sets event activity status to inactive' do
        subject_api.handle
        expect(Event.find_by!(external_id: 'sr:match:1234').active).to be_falsy
      end
    end
  end
end
