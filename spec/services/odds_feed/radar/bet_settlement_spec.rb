describe OddsFeed::Radar::BetSettlementHandler do
  let(:payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<bet_settlement event_id="sr:match:3432" '\
      'product="1" certainty="1" timestamp="1235">'\
        '<outcomes>'\
          '<market id="13">'\
            '<outcome id="sr:player:789" result="1"/>'\
            '<outcome id="sr:player:123" result="0"/>'\
            '<outcome id="sr:player:111" result="0" void_factor="1"/>'\
            '<outcome id="sr:player:222" result="1" void_factor="0.5"/>'\
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

  subject { described_class.new(payload) }

  it 'raises error on invalid message' do
    allow(subject).to receive(:input_data).and_return({})
    expect { subject.handle }.to raise_error(OddsFeed::InvalidMessageError)
  end

  context 'winning bets settlement processing' do
    let!(:winning_bets_set) do
      set = []

      odd.update(value: 6.52)
      first_stakes = [1, 4, 10]
      first_stakes.each do |stake|
        set << create(:bet, :pending, odd: odd, amount: stake)
      end

      odd.update(value: 6.62)
      second_stakes = [2, 5]
      second_stakes.each do |stake|
        set << create(:bet, :pending, odd: odd, amount: stake)
      end

      return set
    end

    before do
      [
        odd_secondary, odd_third, odd_fourth
      ].each do |other_odd|
        create_list(:bet, rand(1..10), :pending, odd: other_odd)
      end

      subject.handle
    end

    it 'settles odd bets with result and void factor' do
      expected_result = Bet.where(status: Bet.statuses[:settled],
                                  result: true,
                                  void_factor: 0.5)
      expect(expected_result.to_a).to match_array(winning_bets_set)
    end
  end

  it 'emits web socket event per bet' do
    create_list(:bet, 10, odd: odd, status: Bet.statuses[:pending])
    subject.handle

    expect(WebSocket::Client.instance)
      .to have_received(:emit)
      .exactly(10)
      .times
  end
end
