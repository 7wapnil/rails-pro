describe WebSocket::SocketIOConnection do
  let(:url) { 'ws://websocket:3000' }
  let(:tcp) { TCPSocketMock.new }
  let(:thread) { ThreadMock.new }
  subject { WebSocket::SocketIOConnection.new(url) }

  before do
    allow(subject).to receive(:tcp).and_return(tcp)
    allow(subject).to receive(:start_listening)
  end

  it 'defines handlers on connect' do
    allow(subject).to receive(:set_handlers)
    subject.connect
    expect(subject).to have_received(:set_handlers)
  end

  it 'updates dead status on disconnect' do
    allow(subject).to receive(:thread).and_return(thread)

    subject.connect
    expect(subject.dead?).to be_falsey
    subject.close
    expect(subject.dead?).to be_truthy
  end

  it 'writes formatted message to socket on emit' do
    allow(tcp).to receive(:write)
    subject.connect
    subject.emit('test', test: 1)
    expect(tcp).to have_received(:write)
  end
end
