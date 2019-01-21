describe ApplicationState do
  subject { described_class.instance }

  describe 'repository' do
    it 'defines defaults status as active' do
      expect(subject.status).to eq(:active)
    end

    it 'returns state model' do
      expect(subject.state).to be_a(::ApplicationState::StateModel)
    end

    it 'state connected by default' do
      expect(subject.state.live_connected).to be_truthy
      expect(subject.state.pre_live_connected).to be_truthy
    end
  end

  describe '.status=' do
    it 'raises error on wrong status' do
      expect { subject.status = :unknown }.to raise_error(StandardError)
    end
  end

  describe 'state model' do
    it 'reads actual state from storage' do
      allow(Rails.cache).to receive(:read)
      subject.state

      expect(Rails.cache)
        .to have_received(:read)
        .with(ApplicationState::StateModel::STATE_STORAGE_KEY)
    end

    it 'stores state in storage on update' do
      allow(Rails.cache).to receive(:write)
      subject.live_connected = false

      expect(Rails.cache)
        .to have_received(:write)
        .with(
          ApplicationState::StateModel::STATE_STORAGE_KEY,
          live_connected: false, pre_live_connected: true
        )
    end

    it 'sends websocket event on state update' do
      subject.live_connected = false
      expect(WebSocket::Client.instance)
        .to have_received(:trigger_app_update)
    end
  end
end
