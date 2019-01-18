describe OddsFeed::Radar::BetSettlementHandler do
  subject { described_class.new(payload) }

  let(:subject_with_input) { described_class.new(payload) }
  let(:payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<bet_settlement event_id="sr:match:3432" '\
      'product="1" certainty="1" timestamp="1235">'\
        '<outcomes>'\
          '<market id="13">'\
            '<outcome id="sr:player:123" result="0"/>'\
            '<outcome id="sr:player:789" result="1"/>'\
            '<outcome id="sr:player:111" result="0" void_factor="1"/>'\
            '<outcome id="sr:player:222" result="1" void_factor="0.5"/>'\
            '<outcome id="sr:player:456" result="0" void_factor="0.5"/>'\
          '</market>'\
        '</outcomes>'\
      '</bet_settlement>'
    )
  end
  let(:market_id) { 'sr:match:3432:13' }
  let(:market) do
    create(:market, status: Market::ACTIVE, external_id: market_id)
  end
  let(:odd) do
    create(:odd, market: market, external_id: 'sr:match:3432:13:sr:player:222')
  end
  let(:odd_secondary) do
    create(:odd, market: market, external_id: 'sr:match:3432:13:sr:player:789')
  end
  let(:odd_third) do
    create(:odd, market: market, external_id: 'sr:match:3432:13:sr:player:123')
  end
  let(:odd_fourth) do
    create(:odd, market: market, external_id: 'sr:match:3432:13:sr:player:111')
  end
  let(:odd_fifth) do
    create(:odd, market: market, external_id: 'sr:match:3432:13:sr:player:456')
  end
  let(:odd_not_from_payload) do
    create(:odd, market: market, external_id: 'sr:match:3432:13:sr:player:999')
  end

  let(:total_bets_count)     { 25 }
  let(:first_odd_bets_count) { 6 }

  it 'raises error on invalid message' do
    allow(subject_with_input).to receive(:input_data).and_return({})
    expect do
      subject_with_input.handle
    end.to raise_error(OddsFeed::InvalidMessageError)
  end

  context 'settled bets processing' do
    let(:currency) { create(:currency) }
    let(:rule_for_refund) do
      create(:entry_currency_rule,
             currency: currency,
             kind: EntryRequest::REFUND,
             min_amount: 10,
             max_amount: 1000)
    end

    before do
      create(:entry_currency_rule,
             currency: currency,
             kind: EntryRequest::WIN,
             min_amount: 10,
             max_amount: 1000)
      create_list(:bet, 6, :accepted, odd: odd, currency: currency)
      create_list(:bet, 4, :accepted, odd: odd_secondary, currency: currency)
      create_list(:bet, 7, :accepted, odd: odd_third, currency: currency)
      create_list(:bet, 3, :accepted, odd: odd_fourth, currency: currency)
      create_list(:bet, 5, :accepted, odd: odd_fifth, currency: currency)

      create_list(:bet, 8, :accepted,
                  odd: odd_not_from_payload, currency: currency)
    end

    it 'calls BetSettelement service to process all affected bets' do
      allow(BetSettelement::Service).to receive(:call)

      subject_with_input.handle

      expect(BetSettelement::Service)
        .to have_received(:call)
        .exactly(total_bets_count)
        .times
    end

    context 'market status' do
      before do
        allow(BetSettelement::Service).to receive(:call)
      end

      it 'sets market status to settled' do
        subject_with_input.handle

        expect(Market.find_by(external_id: market_id).status)
          .to eq(Market::SETTLED)
      end

      it 'updates bets even when market not found' do
        Market.find_by(external_id: market_id).destroy
        allow(subject_with_input).to receive(:process_bets)

        subject_with_input.handle

        expect(subject_with_input)
          .to have_received(:process_bets)
          .at_least(:once)
      end
    end

    context 'with suspended bets' do
      let(:odd) do
        create(:odd, :suspended, external_id: 'sr:match:3432:13:sr:player:222')
      end

      before do
        allow(BetSettelement::Service).to receive(:call)
        subject.handle
      end

      it 'and calls BetSettelement service to process unsuspended bets' do
        expect(BetSettelement::Service)
          .to have_received(:call)
          .exactly(total_bets_count - first_odd_bets_count)
          .times
      end

      it 'and re-validates all suspended bets' do
        expect(Bet.sent_to_internal_validation.count)
          .to eq(first_odd_bets_count)
      end
    end
  end

  it 'settles odd bets with result and void factor' do
    allow(subject_with_input).to receive(:process_bets)
    create_list(:bet, 5,
                odd: odd,
                status: StateMachines::BetStateMachine::ACCEPTED)
    # other bets
    create_list(:bet, 5, status: StateMachines::BetStateMachine::ACCEPTED)
    subject_with_input.handle

    expected_result = Bet.where(
      status: StateMachines::BetStateMachine::SETTLED,
      settlement_status: StateMachines::BetStateMachine::WON,
      void_factor: 0.5
    )
    expect(expected_result.count).to eq(5)
  end

  it 'emits web socket event per bet' do
    allow(subject_with_input).to receive(:process_bets)

    create_list(:bet, 10,
                odd: odd, status: StateMachines::BetStateMachine::ACCEPTED)
    subject_with_input.handle

    expect(WebSocket::Client.instance)
      .to have_received(:emit)
      .exactly(10)
      .times
      .with(WebSocket::Signals::BET_SETTLED, anything)
  end
end
