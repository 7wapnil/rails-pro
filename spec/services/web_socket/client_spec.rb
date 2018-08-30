describe WebSocket::Client.instance do
  let(:connection) { Redis.new }

  before do
    allow(connection).to receive(:publish)
    allow(subject).to receive(:connection).and_return(connection)
  end

  it 'publish a message to channel on emit' do
    subject.emit!('eventName', test: 1)
    json = ActiveSupport::JSON.encode(event: 'eventName', data: { test: 1 })
    expect(connection)
      .to have_received(:publish)
      .with('events', json)
  end
end
