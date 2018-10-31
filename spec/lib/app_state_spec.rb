describe ApplicationState.instance do
  context '.initialize' do
    it 'defines defaults status as active' do
      expect(subject.states[:status]).to eq(:active)
    end
  end

  context '.status=' do
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
end
