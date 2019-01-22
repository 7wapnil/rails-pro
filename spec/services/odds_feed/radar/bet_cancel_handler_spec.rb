describe OddsFeed::Radar::BetCancelHandler do
  subject { described_class.new(payload) }

  let(:pending_status) { StateMachines::BetStateMachine::VALIDATED_INTERNALLY }
  let(:cancelled_status) { StateMachines::BetStateMachine::CANCELLED }

  let(:payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<bet_cancel event_id="sr:match:4711" timestamp="1234000">'\
      '<market specifiers="gamenr=1|pointnr=20" id="520"/>'\
      '</bet_cancel>'
    )
  end

  let(:payload_with_range) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<bet_cancel event_id="sr:match:4711" start_time="1230000" '\
      'end_time="1240000" timestamp="1234000">'\
        '<market specifiers="gamenr=1|pointnr=20" id="520"/>'\
      '</bet_cancel>'
    )
  end

  before do
    before_range = Time.at(1_229_000)
    in_range = Time.at(1_235_000)
    after_range = Time.at(1_241_000)

    event = create(:event, external_id: 'sr:match:4711')
    market_one = create(:market,
                        status: Market::ACTIVE,
                        event: event,
                        external_id: 'sr:match:4711:520/gamenr=1|pointnr=20')
    market_one_odd = create(:odd, market: market_one)

    create_list(:bet, 1, odd: market_one_odd,
                         status: pending_status,
                         created_at: before_range)
    create_list(:bet, 3, odd: market_one_odd, status: pending_status,
                         created_at: in_range)
    create_list(:bet, 1, odd: market_one_odd, status: pending_status,
                         created_at: after_range)

    market_two = create(:market,
                        status: Market::ACTIVE,
                        event: event,
                        external_id: 'sr:match:4711:1000')
    market_two_odd = create(:odd, market: market_two)

    create_list(:bet, 1, odd: market_two_odd, status: pending_status,
                         created_at: before_range)
    create_list(:bet, 3, odd: market_two_odd, status: pending_status,
                         created_at: in_range)
    create_list(:bet, 1, odd: market_two_odd, status: pending_status,
                         created_at: after_range)
  end

  it 'updates markets status' do
    subject.handle

    market = Market
             .find_by!(external_id: 'sr:match:4711:520/gamenr=1|pointnr=20')
    expect(market.status).to eq(Market::CANCELLED)
  end

  describe 'no time range' do
    it 'cancels all market bets' do
      subject.handle
      expect(Bet.where(status: cancelled_status).count).to eq(5)
    end
  end

  describe 'no time range' do
    subject { described_class.new(payload_with_range) }

    it 'cancels all market bets' do
      subject.handle
      expect(Bet.where(status: cancelled_status).count).to eq(3)
    end
  end

  describe 'invalid payload' do
    let(:input_subject) { described_class.new(payload_with_range) }

    it 'raises error if no event id' do
      payload['event_id'] = nil
      allow(input_subject).to receive(:input_data).and_return(payload)

      expect do
        input_subject.handle
      end.to raise_error(OddsFeed::InvalidMessageError)
    end

    it 'raises error if no markets' do
      payload['market'] = nil
      allow(input_subject).to receive(:input_data).and_return(payload)

      expect do
        input_subject.handle
      end.to raise_error(OddsFeed::InvalidMessageError)
    end
  end
end
