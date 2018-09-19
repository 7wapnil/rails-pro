describe OddsFeed::Radar::BetStopHandler do
  let(:payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<bet_stop timestamp="1532353934098" product="3" '\
      'event_id="sr:match:471123" groups="all"/>'
    )
  end

  let(:event) { create(:event, external_id: 'sr:match:471123') }

  subject { described_class.new(payload) }

  it 'suspends event markets' do
    create_list(:market, 5, event: event, status: Market.statuses[:active])
    create_list(:market, 2, status: Market.statuses[:active]) # other event

    subject.handle
    expect(Market.where(status: Market.statuses[:suspended]).count).to eq(5)
    expect(Market.where(status: Market.statuses[:active]).count).to eq(2)
  end

  it 'deactivates event markets' do
    input_data = payload['bet_stop']
    input_data['market_status'] = 'deactivated'
    allow(subject).to receive(:input_data).and_return(input_data)

    create_list(:market, 5, event: event, status: Market.statuses[:active])
    create_list(:market, 2, status: Market.statuses[:active]) # other event

    subject.handle
    expect(Market.where(status: Market.statuses[:inactive]).count).to eq(5)
    expect(Market.where(status: Market.statuses[:active]).count).to eq(2)
  end

  it 'emits one web socket event per market' do
    markets_amount = 5
    create_list(:market,
                markets_amount,
                event: event,
                status: Market.statuses[:active])

    subject.handle
    expect(WebSocket::Client.instance)
      .to have_received(:emit)
      .exactly(markets_amount)
      .times
      .with(WebSocket::Signals::MARKET_UPDATED, anything)
  end

  it 'emits web socket events in batches' do
    allow(subject).to receive(:update_markets)
    markets_amount = 20
    create_list(:market,
                markets_amount,
                event: event,
                status: Market.statuses[:active])

    subject.batch_size = 5
    subject.handle

    expect(subject)
      .to have_received(:update_markets)
      .exactly(4)
      .times
  end
end
