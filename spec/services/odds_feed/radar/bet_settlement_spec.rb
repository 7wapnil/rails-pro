describe OddsFeed::Radar::BetSettlementHandler do
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
  let(:odd) { create(:odd, external_id: 'sr:match:3432:13:sr:player:222') }
  let(:odd_secondary) do
    create(:odd, external_id: 'sr:match:3432:13:sr:player:789')
  end
  let(:odd_third) do
    create(:odd, external_id: 'sr:match:3432:13:sr:player:123')
  end
  let(:odd_fourth) do
    create(:odd, external_id: 'sr:match:3432:13:sr:player:111')
  end
  let(:odd_five) do
    create(:odd, external_id: 'sr:match:3432:13:sr:player:456')
  end

  subject { described_class.new(payload) }

  it 'raises error on invalid message' do
    allow(subject).to receive(:input_data).and_return({})
    expect { subject.handle }.to raise_error(OddsFeed::InvalidMessageError)
  end

  context 'settled bets processing' do
    let(:currency) { create(:currency) }

    let!(:odd_bets) do
      create_list(:bet, 6, :pending, odd: odd, currency: currency)
    end

    let(:bet) { odd_bets.first }
    let(:wallet) { create(:wallet, customer: bet.customer) }

    let!(:rule) do
      create(:entry_currency_rule,
             currency: currency,
             kind: EntryRequest.kinds[:win],
             min_amount: 10,
             max_amount: 1000)
    end

    before do
      create_list(:bet, 2, :pending, odd: odd_secondary, currency: currency)
      create_list(:bet, 4, :pending, odd: odd_third, currency: currency)
      create_list(:bet, 7, :pending, odd: odd_fourth, currency: currency)
      create_list(:bet, 3, :pending, odd: odd_five, currency: currency)

      subject.handle
    end

    it 'calls BetSettelement service to process all affected bets' do
      allow(BetSettelement::Service).to receive(:call)

      subject.handle

      expect(BetSettelement::Service)
        .to have_received(:call)
        .exactly(22)
        .times
    end
  end

  it 'settles odd bets with result and void factor' do
    allow(subject).to receive(:process_bets)
    create_list(:bet, 5, odd: odd, status: Bet.statuses[:pending])
    create_list(:bet, 5, status: Bet.statuses[:pending]) # other bets
    subject.handle

    expected_result = Bet.where(status: Bet.statuses[:settled],
                                result: true,
                                void_factor: 0.5)
    expect(expected_result.count).to eq(5)
  end

  it 'emits web socket event per bet' do
    allow(subject).to receive(:process_bets)

    create_list(:bet, 10, odd: odd, status: Bet.statuses[:pending])
    subject.handle

    expect(WebSocket::Client.instance)
      .to have_received(:emit)
      .exactly(10)
      .times
  end
end
