describe OddsFeed::Radar::AliveHandler do
  let(:alive_payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<alive product="1" timestamp="1532353934098" subscribed="1"/>'
    )
  end

  subject do
    OddsFeed::Radar::AliveHandler.new(alive_payload)
  end

  it 'process request using correct message builder options' do
    allow_any_instance_of(::Radar::AliveMessage).to receive(:process!)
    expect(::Radar::AliveMessage)
      .to receive(:from_hash)
      .with(
        'product' => '1',
        'timestamp' => '1532353934098',
        'subscribed' => '1'
      ).once.and_call_original
    subject.handle
  end

  it 'calls process on message created' do
    expect_any_instance_of(::Radar::AliveMessage).to receive(:process!).once
    subject.handle
  end
end
