describe WebSocket::Client do
  let(:connection) do
    connection = WebSocket::SocketIOConnection.new('wss://websocket')
    allow(connection).to receive(:connect)
    allow(connection).to receive(:emit)
    connection
  end

  subject { WebSocket::Client.new(connection) }

  it 'should call connection method on emit' do
    subject.emit('eventName', test: 1)
    expect(connection)
      .to have_received(:emit)
      .with('eventName', test: 1)
  end

  it 'should try to reconnect if connection is dead' do
    allow(connection).to receive(:dead?).and_return(true)
    subject.emit('eventName', test: 1)
    expect(connection).to have_received(:connect)
  end

  it 'should reuse connection if alive' do
    allow(connection).to receive(:dead?).and_return(false)
    subject.emit('eventName', test: 1)
    expect(connection).not_to have_received(:connect)
  end
end
