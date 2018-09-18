describe 'BetSettlementHandler integration' do
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

  subject { OddsFeed::Radar::BetSettlementHandler.new(payload) }

  let(:odd_entire_lose) do
    create(:odd, external_id: 'sr:match:3432:13:sr:player:123')
  end
  let(:odd_entire_win) do
    create(:odd, external_id: 'sr:match:3432:13:sr:player:789')
  end
  let(:odd_full_refund) do
    create(:odd, external_id: 'sr:match:3432:13:sr:player:111')
  end
  let(:odd_half_win) do
    create(:odd, external_id: 'sr:match:3432:13:sr:player:222')
  end
  let(:odd_lose_half_refund) do
    create(:odd, external_id: 'sr:match:3432:13:sr:player:456')
  end

  let(:currency) { create(:currency) }

  let!(:rule) do
    create(:entry_currency_rule,
           currency: currency,
           kind: EntryRequest.kinds[:win],
           min_amount: 10,
           max_amount: 1000)
  end

  context 'single bets checks, wins check only' do
    EXAMPLES = [
      { name: 'entire win', odd_name: 'odd_entire_win',
        odd_value: 1.65, stake: 22.4,
        win: 36.96 },
      { name: 'entire lose', odd_name: 'odd_entire_lose',
        odd_value: 1.65, stake: 22.4,
        win: nil },
      { name: 'full refund', odd_name: 'odd_full_refund',
        odd_value: 1.65, stake: 22.4,
        win: nil },
      { name: 'half win', odd_name: 'odd_half_win',
        odd_value: 1.5, stake: 100,
        win: 75 },
      { name: 'half refund', odd_name: 'odd_lose_half_refund',
        odd_value: 1.65, stake: 22.4,
        win: nil }
    ].freeze

    EXAMPLES.each do |state|
      it state[:name] do
        odd = send(state[:odd_name])
        odd.value = state[:odd_value]
        create(:bet,
               :pending, odd: odd, amount: state[:stake], currency: currency)

        subject.handle

        if state[:win].nil?
          expect(BalanceEntry.count).to eq 0
        else
          expect(BalanceEntry.last.amount).to be_within(0.01).of(state[:win])
        end
      end
    end
  end

  it 'pay outs win for multiple bets with different odd values' do
    odd_entire_win.value = 2
    create(:bet, :pending, odd: odd_entire_win, amount: 20, currency: currency)
    odd_entire_win.value = 3
    create(:bet, :pending, odd: odd_entire_win, amount: 10, currency: currency)

    subject.handle

    expect(BalanceEntry.sum(&:amount)).to be_within(0.01).of(70)
  end

  xit 'checks for refund amounts'
  xit 'handles currency rules on win'
  xit 'handles currency rules on refund'
end
