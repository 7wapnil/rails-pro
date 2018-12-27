describe ApplicationState do
  subject { described_class.instance }

  describe '.initialize' do
    it 'defines defaults status as active' do
      expect(subject.status).to eq(:active)
    end
  end

  describe '.status=' do
    it 'sends web socket event on status change' do
      subject.status = :inactive
      expect(WebSocket::Client.instance)
        .to have_received(:emit)
        .with(WebSocket::Signals::APP_STATE_UPDATED, anything)
    end

    it 'raises error on wrong status' do
      expect { subject.status = :unknown }.to raise_error(StandardError)
    end
  end

  describe 'storage' do
    subject { described_class.new }

    let(:subject_with_store) { described_class.instance }

    it 'reads actual state from storage on init' do
      expect(subject.live_connected).to be_truthy
      expect(subject.pre_live_connected).to be_truthy
    end

    it 'notify state update on init' do
      described_class.new
      expect(WebSocket::Client.instance)
        .to have_received(:emit)
        .with(WebSocket::Signals::APP_STATE_UPDATED, anything)
    end

    it 'stores state on update' do
      allow(subject_with_store).to receive(:store_app_state)
      subject_with_store.live_connected = false
      expect(subject_with_store).to have_received(:store_app_state)
    end

    it 'emits websocket on state update' do
      subject.live_connected = false
      expect(WebSocket::Client.instance)
        .to have_received(:emit)
        .twice
        .with(WebSocket::Signals::APP_STATE_UPDATED, anything)
    end
  end
end