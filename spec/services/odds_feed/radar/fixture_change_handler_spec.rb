describe OddsFeed::Radar::FixtureChangeHandler do
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

  subject { described_class.new(payload) }

  before do
    allow(subject).to receive(:api_event) { api_event }
  end

  after do
    subject.handle
  end

  context 'new event' do
    it 'logs event create message' do
      expect(subject).to receive(:log_on_create)
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

  context 'existing event' do
    let(:event) do
      create(:event,
             external_id: payload['fixture_change']['event_id'],
             active: true)
    end

    before do
      allow(subject).to receive(:event) { event }
    end

    it 'calls #update_from! on found event' do
      expect(event).to receive(:update_from!).with(api_event)
    end

    it 'logs event update message' do
      expect(subject).to receive(:log_on_update)
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
        subject.handle
        expect(Event.find_by!(external_id: 'sr:match:1234').active).to be_falsy
      end
    end
  end
end
