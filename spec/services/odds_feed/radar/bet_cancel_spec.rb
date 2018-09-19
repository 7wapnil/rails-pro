describe OddsFeed::Radar::BetCancelHandler do
  let!(:odd) do
    event = create(:event, external_id: 'sr:match:4711')
    market = create(:market, event: event)
    create(:odd, market: market)
  end

  let(:pending) { Bet.statuses[:pending] }

  let(:payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<bet_cancel event_id="sr:match:4711" start_time="1230000" '\
      'end_time="1240000" timestamp="1234000"/>'
    )
  end

  let(:input_data) { payload['bet_cancel'] }

  subject { OddsFeed::Radar::BetCancelHandler.new(payload) }

  it 'cancels bets in a time range' do
    allow(subject).to receive(:input_data).and_return(input_data)

    before_range = Time.at(1_229_000)
    in_range = Time.at(1_235_000)
    after_range = Time.at(1_241_000)

    create_list(:bet, 1, odd: odd, status: pending, created_at: before_range)
    create_list(:bet, 3, odd: odd, status: pending, created_at: in_range)
    create_list(:bet, 1, odd: odd, status: pending, created_at: after_range)

    subject.handle

    expect(Bet.where(status: pending).count).to eq(2)
    expect(Bet.where(status: Bet.statuses[:cancelled]).count).to eq(3)
  end

  it 'cancels bets from start time point' do
    input_data.delete('end_time')
    allow(subject).to receive(:input_data).and_return(input_data)

    before_start = Time.at(1_220_000)
    after_start = Time.at(1_240_000)

    create_list(:bet, 1, odd: odd, status: pending, created_at: before_start)
    create_list(:bet, 3, odd: odd, status: pending, created_at: after_start)

    subject.handle

    expect(Bet.where(status: Bet.statuses[:cancelled]).count).to eq(3)
    expect(Bet.where(status: pending).count).to eq(1)
  end

  it 'cancels bets before end time point' do
    input_data.delete('start_time')
    allow(subject).to receive(:input_data).and_return(input_data)

    before_end = Time.at(1_230_000)
    after_end = Time.at(1_250_000)

    create_list(:bet, 3, odd: odd, status: pending, created_at: before_end)
    create_list(:bet, 1, odd: odd, status: pending, created_at: after_end)

    subject.handle

    expect(Bet.where(status: Bet.statuses[:cancelled]).count).to eq(3)
    expect(Bet.where(status: pending).count).to eq(1)
  end

  it 'raise error if not time range defined' do
    input_data.delete('start_time')
    input_data.delete('end_time')
    allow(subject).to receive(:input_data).and_return(input_data)

    expect { subject.handle }.to raise_error(OddsFeed::InvalidMessageError)
  end

  it 'emits one web socket event per bet' do
    allow(subject).to receive(:input_data).and_return(input_data)
    bets_amount = 5
    create_list(:bet,
                bets_amount,
                odd: odd,
                status: pending,
                created_at: Time.at(1_235_000))

    subject.handle
    expect(WebSocket::Client.instance)
      .to have_received(:emit)
      .exactly(bets_amount)
      .times
      .with(WebSocket::Signals::BET_CANCELLED, anything)
  end

  it 'emits web socket events in batches' do
    allow(subject).to receive(:input_data).and_return(input_data)
    allow(subject).to receive(:emit_websocket_signals)
    bets_amount = 20
    create_list(:bet,
                bets_amount,
                odd: odd,
                status: pending,
                created_at: Time.at(1_235_000))

    subject.batch_size = 5
    subject.handle

    expect(subject)
      .to have_received(:emit_websocket_signals)
      .exactly(4)
      .times
  end
end
