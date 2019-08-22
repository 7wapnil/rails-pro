# frozen_string_literal: true

describe OddsFeed::Radar::BetSettlementHandler do
  subject { described_class.new(payload) }

  let(:subject_with_input) { described_class.new(payload) }
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
            '<outcome id="sr:player:333" result="1" void_factor="1"/>'\
            '<outcome id="sr:player:444" result="0" void_factor="1.0"/>'\
          '</market>'\
        '</outcomes>'\
      '</bet_settlement>'
    )
  end
  let(:market_id) { 'sr:match:3432:13/hcp=3.5' }
  let(:market) do
    create(:market, status: Market::ACTIVE, external_id: market_id)
  end
  let!(:primary_currency) { create(:currency, :primary) }
  let(:odd) do
    create(:odd, market: market,
                 external_id: 'sr:match:3432:13/hcp=3.5:sr:player:222')
  end
  let(:odd_secondary) do
    create(:odd, market: market,
                 external_id: 'sr:match:3432:13/hcp=3.5:sr:player:789')
  end
  let(:odd_third) do
    create(:odd, market: market,
                 external_id: 'sr:match:3432:13/hcp=3.5:sr:player:123')
  end
  let(:odd_fourth) do
    create(:odd, market: market,
                 external_id: 'sr:match:3432:13/hcp=3.5:sr:player:111')
  end
  let(:odd_fifth) do
    create(:odd, market: market,
                 external_id: 'sr:match:3432:13/hcp=3.5:sr:player:456')
  end
  let(:odd_sixth) do
    create(:odd, market: market,
                 external_id: 'sr:match:3432:13/hcp=3.5:sr:player:333')
  end
  let(:odd_seventh) do
    create(:odd, market: market,
                 external_id: 'sr:match:3432:13/hcp=3.5:sr:player:444')
  end
  let(:odd_not_from_payload) do
    create(:odd, market: market,
                 external_id: 'sr:match:3432:13/hcp=3.5:sr:player:999')
  end

  let(:total_bets_count)     { 28 }
  let(:first_odd_bets_count) { 6 }

  let(:mocked_entry_request) { double }

  include_context 'asynchronous to synchronous'

  before do
    allow(WebSocket::Client.instance).to receive(:trigger_event_update)
  end

  it 'raises error on invalid message' do
    allow(subject_with_input).to receive(:input_data).and_return({})
    expect do
      subject_with_input.handle
    end.to raise_error(OddsFeed::InvalidMessageError)
  end

  describe 'uncertain settlement for prelive markets' do
    let(:original_message) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <bet_settlement
          event_id="sr:match:3432"
          product="1"
          certainty="2"
          timestamp="1235">
          <outcomes>
            <market id="13" specifiers="hcp=3.5">
              <outcome id="sr:player:123" result="0"/>
              <outcome id="sr:player:789" result="1"/>
              <outcome id="sr:player:111" result="0" void_factor="1"/>
              <outcome id="sr:player:222" result="1" void_factor="0.5"/>
              <outcome id="sr:player:456" result="0" void_factor="0.5"/>
            </market>
            <market id="14" specifiers="hcp=3.5">
              <outcome id="sr:player:123" result="0"/>
              <outcome id="sr:player:789" result="1"/>
              <outcome id="sr:player:111" result="0" void_factor="1"/>
              <outcome id="sr:player:222" result="1" void_factor="0.5"/>
              <outcome id="sr:player:456" result="0" void_factor="0.5"/>
            </market>
            <market id="15" specifiers="hcp=3.5">
              <outcome id="sr:player:123" result="0"/>
              <outcome id="sr:player:789" result="1"/>
              <outcome id="sr:player:111" result="0" void_factor="1"/>
              <outcome id="sr:player:222" result="1" void_factor="0.5"/>
              <outcome id="sr:player:456" result="0" void_factor="0.5"/>
            </market>
          </outcomes>
        </bet_settlement>
      XML
    end

    let(:payload) { XmlParser.parse(original_message) }

    before do
      allow(subject_with_input).to receive(:settle_bets_for_market)

      allow(subject_with_input)
        .to receive(:find_market_template_for)
        .with('13')
        .and_return(build(:market_template, :products_live))

      allow(subject_with_input)
        .to receive(:find_market_template_for)
        .with('14')
        .and_return(build(:market_template, :products_prelive))

      allow(subject_with_input)
        .to receive(:find_market_template_for)
        .with('15')
        .and_return(build(:market_template, :products_all))
    end

    context 'certainty = 1' do
      before do
        payload['bet_settlement']['certainty'] = '1'
        subject_with_input.handle
      end

      it 'processes live market' do
        expect(subject_with_input)
          .to have_received(:settle_bets_for_market)
          .with(payload['bet_settlement']['outcomes']['market'][0])
      end

      it 'skips prelive market' do
        expect(subject_with_input)
          .not_to have_received(:settle_bets_for_market)
          .with(payload['bet_settlement']['outcomes']['market'][1])
      end

      it 'processes market for both products' do
        expect(subject_with_input)
          .to have_received(:settle_bets_for_market)
          .with(payload['bet_settlement']['outcomes']['market'][2])
      end
    end

    context 'certainty = 2' do
      before do
        subject_with_input.handle
      end

      it 'processes live market' do
        expect(subject_with_input)
          .to have_received(:settle_bets_for_market)
          .with(payload['bet_settlement']['outcomes']['market'][0])
      end

      it 'processes prelive market' do
        expect(subject_with_input)
          .to have_received(:settle_bets_for_market)
          .with(payload['bet_settlement']['outcomes']['market'][1])
      end

      it 'processes market for both products' do
        expect(subject_with_input)
          .to have_received(:settle_bets_for_market)
          .with(payload['bet_settlement']['outcomes']['market'][2])
      end
    end
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
      create_list(:bet, 2, :accepted, odd: odd, currency: currency)
      create_list(:bet, 4, :accepted, odd: odd_secondary, currency: currency)
      create_list(:bet, 7, :accepted, odd: odd_third, currency: currency)
      create_list(:bet, 3, :accepted, odd: odd_fourth, currency: currency)
      create_list(:bet, 1, :accepted, odd: odd_fifth, currency: currency)
      create_list(:bet, 6, :accepted, odd: odd_sixth, currency: currency)
      create_list(:bet, 5, :accepted, odd: odd_seventh, currency: currency)

      create_list(:bet, 8, :accepted,
                  odd: odd_not_from_payload, currency: currency)

      allow(subject_with_input).to receive(:skip_uncertain_settlement?)
    end

    it 'calls Settlement service to process all bets' do
      allow(Bets::SettlementWorker).to receive(:perform_async)

      subject_with_input.handle

      expect(Bets::SettlementWorker)
        .to have_received(:perform_async)
        .exactly(total_bets_count)
        .times
    end

    it 'updates market status to SETTLED and creates snapshot' do
      allow(Bets::SettlementWorker).to receive(:perform_async)

      subject_with_input.handle

      expect(Market.find_by(external_id: market_id)).to have_attributes(
        status: StateMachines::MarketStateMachine::SETTLED,
        previous_status: StateMachines::MarketStateMachine::ACTIVE
      )
    end
  end

  it 'settles odd bets with result and void factor' do
    allow(subject_with_input).to receive(:skip_uncertain_settlement?)
    create_list(:bet, 3,
                odd: odd_sixth,
                status: StateMachines::BetStateMachine::ACCEPTED)
    # other bets
    create_list(:bet, 3, status: StateMachines::BetStateMachine::ACCEPTED)
    subject_with_input.handle

    expected_result = Bet.where(
      status: StateMachines::BetStateMachine::SETTLED,
      settlement_status: StateMachines::BetStateMachine::VOIDED,
      void_factor: 1
    )
    expect(expected_result.count).to eq(3)
  end

  it 'settles only accepted bets with odds' do
    allow(subject_with_input).to receive(:skip_uncertain_settlement?)
    create_list(:bet, 3,
                odd: odd_sixth,
                status: StateMachines::BetStateMachine::ACCEPTED)
    # other bets
    create(:bet, status: StateMachines::BetStateMachine::ACCEPTED)
    create(:bet, :lost, status: StateMachines::BetStateMachine::SETTLED)
    create(:bet, status: StateMachines::BetStateMachine::FAILED)
    create(:bet, status: StateMachines::BetStateMachine::REJECTED)
    subject_with_input.handle

    expected_result = Bet.where(
      status: StateMachines::BetStateMachine::SETTLED,
      settlement_status: StateMachines::BetStateMachine::VOIDED
    )
    expect(expected_result.count).to eq(3)
  end

  it 'does not settle odd bets with result and half void factor' do
    allow(subject_with_input).to receive(:skip_uncertain_settlement?)
    create(:bet, odd: odd, status: StateMachines::BetStateMachine::ACCEPTED)
    expect { subject_with_input.handle }
      .to raise_error(::Bets::NotSupportedError, 'Void factor is not supported')
  end

  it 'settles odd bets without result, but with void factor, even as float' do
    allow(subject_with_input).to receive(:skip_uncertain_settlement?)
    create_list(:bet, 3,
                odd: odd_seventh,
                status: StateMachines::BetStateMachine::ACCEPTED)
    # other bets
    create_list(:bet, 3, status: StateMachines::BetStateMachine::ACCEPTED)
    subject_with_input.handle

    expected_result = Bet.where(
      status: StateMachines::BetStateMachine::SETTLED,
      settlement_status: StateMachines::BetStateMachine::VOIDED,
      void_factor: 1
    )
    expect(expected_result.count).to eq(3)
  end

  it 'does not settle odd bets without result, but with half void factor' do
    allow(subject_with_input).to receive(:skip_uncertain_settlement?)
    create(:bet, odd: odd_fifth,
                 status: StateMachines::BetStateMachine::ACCEPTED)
    expect { subject_with_input.handle }
      .to raise_error(::Bets::NotSupportedError, 'Void factor is not supported')
  end
end
