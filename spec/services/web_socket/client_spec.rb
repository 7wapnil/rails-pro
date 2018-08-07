describe 'websocket_client' do
  let(:connection) do
    connection = WebSocket::SocketIOConnection.new('wss://websocket')
    allow(connection).to receive(:connect)
    allow(connection).to receive(:emit)
    connection
  end

  subject do
    client = WebSocket::Client.instance
    allow(client).to receive(:connection).and_return(connection)
    client
  end

  it 'calls connection emit method on message' do
    subject.emit('eventName', test: 1)
    expect(connection)
      .to have_received(:emit)
      .with('eventName', test: 1)
  end

  it 're-creates connection if previous is dead' do
    allow(connection).to receive(:dead?).and_return(true)
    allow(subject).to receive(:reset_connection)
    subject.emit('eventName', test: 1)
    expect(subject).to have_received(:reset_connection)
  end

  it 'connects to socket if connection is not established' do
    allow(connection).to receive(:established?).and_return(false)
    subject.emit('eventName', test: 1)
    expect(connection).to have_received(:connect)
  end

  it 're-uses connection if alive' do
    allow(subject).to receive(:reset_connection)
    allow(connection).to receive(:dead?).and_return(false)
    allow(connection).to receive(:established?).and_return(true)

    subject.emit('eventName', test: 1)

    expect(subject).not_to have_received(:reset_connection)
    expect(connection).not_to have_received(:connect)
  end
end
