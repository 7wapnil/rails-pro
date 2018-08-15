describe OddsFeed::Radar::AliveHandler do
  let(:alive_payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<alive product="1" timestamp="1532353934098" subscribed="1"/>'
    )
  end

  let(:alive_data) do
    alive_payload['alive']
  end

  subject do
    OddsFeed::Radar::AliveHandler.new(alive_payload)
  end

  let(:message) { build(:alive_message) }

  it 'delegates message logic to AliveMessage' do
    allow(::Radar::AliveMessage).to receive(:from_hash).and_return(message)
    allow(message).to receive(:save).and_return(message)

    expect(::Radar::AliveMessage).to receive(:from_hash).with(alive_data)
    expect(message).to receive(:save).with no_args
    subject.handle
  end

  context 'non_alive' do
    let(:non_alive_payload) do
      XmlParser.parse(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
        '<alive product="1" timestamp="1532353934098" subscribed="0"/>'
      )
    end

    subject do
      OddsFeed::Radar::AliveHandler.new(non_alive_payload)
    end

    it 'recover on non_alive message' do
      allow(::Radar::AliveMessage).to receive(:from_hash).and_return(message)
      allow(message).to receive(:save).and_return(message)
      allow(message).to receive(:subscribed?).and_return(false)

      expect(OddsFeed::Radar::SubscriptionRecovery)
        .to receive(:call)
        .with(product_id: message.product_id, start_at: anything)
      subject.handle
    end
  end
end
