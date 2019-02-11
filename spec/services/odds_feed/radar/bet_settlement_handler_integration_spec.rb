describe OddsFeed::Radar::BetSettlementHandler, '#integration' do
  subject { described_class.new(payload) }

  let(:payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<bet_settlement event_id="sr:match:3432" '\
      'product="1" certainty="1" timestamp="1235">'\
        '<outcomes>'\
          '<market id="13" specifiers="hcp=3.5">'\
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

  let(:odd_entire_lose) do
    create(:odd, external_id: 'sr:match:3432:13/hcp=3.5:sr:player:123')
  end
  let(:odd_entire_win) do
    create(:odd, external_id: 'sr:match:3432:13/hcp=3.5:sr:player:789')
  end
  let(:odd_full_refund) do
    create(:odd, external_id: 'sr:match:3432:13/hcp=3.5:sr:player:111')
  end
  let(:odd_half_win) do
    create(:odd, external_id: 'sr:match:3432:13/hcp=3.5:sr:player:222')
  end
  let(:odd_lose_half_refund) do
    create(:odd, external_id: 'sr:match:3432:13/hcp=3.5:sr:player:456')
  end

  let(:currency) { create(:currency) }

  before do
    create(:entry_currency_rule,
           currency: currency,
           kind: EntryRequest::WIN,
           min_amount: 10,
           max_amount: 1000)
    create(:entry_currency_rule,
           currency: currency,
           kind: EntryRequest::REFUND,
           min_amount: 1,
           max_amount: 1000)
  end

  BETS_OUTCOME_EXAMPLES = [
    { name: 'entire win', odd_name: 'odd_entire_win',
      odd_value: 1.65, stake: 22.4,
      win: 36.96, refund: nil, records_count: 1 },
    { name: 'entire lose', odd_name: 'odd_entire_lose',
      odd_value: 1.65, stake: 22.4,
      win: nil, refund: nil, records_count: 0 },
    { name: 'full refund', odd_name: 'odd_full_refund',
      odd_value: 1.65, stake: 22.4,
      win: nil, refund: 22.4, records_count: 1 },
    { name: 'half win, half refund', odd_name: 'odd_half_win',
      odd_value: 1.5, stake: 100,
      win: 75, refund: 50, records_count: 1 },
    { name: 'lose, half refund', odd_name: 'odd_lose_half_refund',
      odd_value: 1.65, stake: 22.4,
      win: nil, refund: 11.2, records_count: 1 }
  ].freeze

  context 'single bets map checks, wins only' do
    BETS_OUTCOME_EXAMPLES.each do |state|
      describe state[:name] do
        before do
          odd = send(state[:odd_name])
          odd.value = state[:odd_value]
          create(:bet, :accepted,
                 odd: odd, amount: state[:stake], currency: currency)

          subject.handle
        end

        it 'creates correct number of balance entries' do
          expect(BalanceEntry.all.length).to eq state[:records_count]
        end

        if state[:win]
          it 'adds win to balance' do
            expect(BalanceEntry.find_by(amount: state[:win])).to be_truthy
          end
        end

        if state[:refund] && !state[:win]
          it 'adds refund to balance' do
            expect(BalanceEntry.find_by(amount: state[:refund])).to be_truthy
          end
        end
      end
    end
  end

  it 'pay outs win for multiple bets with different odd values' do
    odd_entire_win.value = 2
    create(:bet, :accepted, odd: odd_entire_win, amount: 20, currency: currency)
    odd_entire_win.value = 3
    create(:bet, :accepted, odd: odd_entire_win, amount: 10, currency: currency)

    subject.handle

    expect(BalanceEntry.sum(&:amount)).to be_within(0.01).of(70)
  end
end
