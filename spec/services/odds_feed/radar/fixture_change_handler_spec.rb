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

  subject { described_class.new(payload) }

  before do
    allow(subject).to receive(:api_event) { api_event }
  end

  after do
    subject.handle
  end

  context 'new event' do
    it 'calls #save! on retrieved event' do
      expect(api_event).to receive(:save!)
    end

    it 'logs event create message' do
      expect(Rails.logger)
        .to receive(:info)
        .with('Creating event with external ID sr:match:1234')
    end

    it 'sends notification to websocket server' do
      event = api_event

      expect(WebSocket::Client.instance)
        .to receive(:emit)
        .with(WebSocket::Signals::UPDATE_EVENT,
              hash_including(name: event.name, start_at: event.start_at))
    end
  end

  context 'existing event' do
    let(:event) do
      create(:event, external_id: payload['fixture_change']['event_id'])
    end

    before do
      allow(subject).to receive(:event) { event }
    end

    it 'calls #update_from! on found event' do
      expect(event).to receive(:update_from!).with(api_event)
    end

    it 'logs event update message' do
      msg = <<-MESSAGE
        Updating event with external ID sr:match:1234 \
        on change type 'format'
      MESSAGE
      expect(Rails.logger).to receive(:info).with(msg.squish)
    end

    it 'sends notification to websocket server' do
      expect(WebSocket::Client.instance)
        .to receive(:emit)
        .with(WebSocket::Signals::UPDATE_EVENT,
              hash_including(name: event.name, start_at: event.start_at))
    end
  end
end
