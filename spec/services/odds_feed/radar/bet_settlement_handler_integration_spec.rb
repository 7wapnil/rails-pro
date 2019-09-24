# frozen_string_literal: true

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

  let!(:primary_currency) { create(:currency, :primary) }
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

  include_context 'asynchronous to synchronous'
  include_context 'base_currency'

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

    allow(WebSocket::Client.instance).to receive(:trigger_event_update)
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
      win: nil, refund: 22.4, records_count: 1 }
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

        it 'creates correct number of entries' do
          expect(Entry.all.length).to eq state[:records_count]
        end

        if state[:win]
          it 'adds win to entry' do
            expect(Entry.find_by(amount: state[:win])).to be_truthy
          end
        end

        if state[:refund] && !state[:win]
          it 'adds refund to entry' do
            expect(Entry.find_by(amount: state[:refund])).to be_truthy
          end
        end
      end
    end

    context 'half win, half refund' do
      let(:odd) { odd_half_win }
      let!(:bet) do
        create(:bet, :accepted, odd: odd, amount: 100, currency: currency)
      end

      it 'raises an error' do
        expect { subject.handle }.to raise_error(
          ::Bets::NotSupportedError,
          'Void factor is not supported'
        )
      end

      it 'does not create balance entry requests' do
        expect do
          subject.handle
        rescue ::Bets::NotSupportedError
        end.not_to change(EntryRequest, :count)
      end

      it 'does not create balance entries' do
        expect do
          subject.handle
        rescue ::Bets::NotSupportedError
        end.not_to change(Entry, :count)
      end

      it 'moves bet to pending manual settlement status' do
        subject.handle
      rescue ::Bets::NotSupportedError
        expect(bet.reload.status).to eq(Bet::PENDING_MANUAL_SETTLEMENT)
      end
    end

    context 'lose, half refund' do
      let(:odd) { odd_lose_half_refund }
      let!(:bet) do
        create(:bet, :accepted, odd: odd, amount: 22.4, currency: currency)
      end

      it 'raises an error' do
        expect { subject.handle }.to raise_error(
          ::Bets::NotSupportedError,
          'Void factor is not supported'
        )
      end

      it 'does not create balance entry requests' do
        expect do
          subject.handle
        rescue ::Bets::NotSupportedError
        end.not_to change(EntryRequest, :count)
      end

      it 'does not create balance entries' do
        expect do
          subject.handle
        rescue ::Bets::NotSupportedError
        end.not_to change(Entry, :count)
      end

      it 'moves bet to pending manual settlement status' do
        subject.handle
      rescue ::Bets::NotSupportedError
        expect(bet.reload.status).to eq(Bet::PENDING_MANUAL_SETTLEMENT)
      end
    end
  end

  it 'pay outs win for multiple bets with different odd values' do
    odd_entire_win.value = 2
    create(:bet, :accepted, odd: odd_entire_win, amount: 20, currency: currency)
    odd_entire_win.value = 3
    create(:bet, :accepted, odd: odd_entire_win, amount: 10, currency: currency)

    subject.handle

    expect(Entry.sum(&:amount)).to be_within(0.01).of(70)
  end
end
