# frozen_string_literal: true

describe Radar::BetCancelWorker do
  subject { described_class.new.perform(payload) }

  let(:pending_status) { StateMachines::BetStateMachine::VALIDATED_INTERNALLY }
  let(:cancelled_status) { StateMachines::BetStateMachine::CANCELLED_BY_SYSTEM }

  let(:payload) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<bet_cancel event_id="sr:match:4711" timestamp="1234000">'\
    '<market specifiers="gamenr=1|pointnr=20" id="520"/>'\
    '</bet_cancel>'
  end

  let(:payload_with_range) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<bet_cancel event_id="sr:match:4711" start_time="1230000" '\
    'end_time="1240000" timestamp="1234000">'\
      '<market specifiers="gamenr=1|pointnr=20" id="520"/>'\
    '</bet_cancel>'
  end

  let(:before_range) { Time.at(1_229_000) }
  let(:in_range) { Time.at(1_235_000) }
  let(:after_range) { Time.at(1_241_000) }

  let(:event) { create(:event, external_id: 'sr:match:4711') }
  let(:market_one) do
    create(:market,
           status: Market::ACTIVE,
           event: event,
           external_id: 'sr:match:4711:520/gamenr=1|pointnr=20')
  end
  let(:market_one_odd) { create(:odd, market: market_one) }
  let(:won_bets_in_range) do
    create_list(:bet, rand(1..4), :won,
                odd: market_one_odd,
                status: pending_status,
                created_at: in_range,
                customer: build(:customer))
  end
  let!(:control_bets) do
    [
      create(:bet, odd: market_one_odd,
                   status: pending_status,
                   created_at: before_range,
                   customer: build(:customer)),
      *won_bets_in_range,
      create(:bet, odd: market_one_odd,
                   status: pending_status,
                   created_at: after_range,
                   customer: build(:customer))
    ]
  end

  let(:market_two) do
    create(:market, status: StateMachines::MarketStateMachine::ACTIVE,
                    event: event,
                    external_id: 'sr:match:4711:1000')
  end
  let(:market_two_odd) { create(:odd, market: market_two) }
  let!(:excluded_bets) do
    [
      create(:bet, odd: market_two_odd,
                   status: pending_status,
                   created_at: before_range),
      *create_list(:bet, rand(1..4), odd: market_two_odd,
                                     status: pending_status,
                                     created_at: in_range),
      create(:bet, odd: market_two_odd,
                   status: pending_status,
                   created_at: after_range)
    ]
  end

  let!(:wallets) do
    control_bets.map do |bet|
      create(:wallet, customer: bet.customer, currency: bet.currency)
    end
  end
  let!(:balances) do
    wallets.map do |wallet|
      create(:balance, :real_money, amount: 10_000, wallet: wallet)
    end
  end

  let(:win_entry_requests) do
    won_bets_in_range.map do |bet|
      create(:entry_request, :win, :internal,
             origin: bet,
             initiator: bet.customer,
             customer: bet.customer,
             currency: bet.currency)
    end
  end
  let!(:placement_entry_requests) do
    control_bets.map do |bet|
      create(:entry_request, :bet, :internal,
             origin: bet,
             initiator: bet.customer,
             customer: bet.customer,
             currency: bet.currency)
    end
  end
  let!(:entry_requests) { [*win_entry_requests, *placement_entry_requests] }

  let(:winnings) do
    win_entry_requests.map do |request|
      wallet = Wallet.find_by(currency: request.currency,
                              customer: request.customer)
      create(:entry, kind: request.kind,
                     origin: request.origin,
                     amount: request.amount,
                     entry_request: request,
                     wallet: wallet)
    end
  end
  let!(:placement_entries) do
    placement_entry_requests.map do |request|
      wallet = Wallet.find_by(currency: request.currency,
                              customer: request.customer)
      create(:entry, kind: request.kind,
                     origin: request.origin,
                     amount: request.amount,
                     entry_request: request,
                     wallet: wallet)
    end
  end
  let!(:entries) { [winnings, placement_entries].flatten }

  let!(:entry_currency_rules) do
    entry_requests.map do |entry_request|
      create(:entry_currency_rule,
             currency: entry_request.currency,
             min_amount: -10_000,
             max_amount: 10_000,
             kind: EntryKinds::SYSTEM_BET_CANCEL)
    end
  end

  let(:found_cancelled_bets_ids) do
    Bet.where(status: cancelled_status).pluck(:id)
  end

  context 'market statuses' do
    before { subject }

    it 'are not updated for markets in payload' do
      expect(market_one.reload).to have_attributes(
        status: StateMachines::MarketStateMachine::ACTIVE,
        previous_status: StateMachines::MarketStateMachine::ACTIVE
      )
    end

    it 'are not updated for markets not in payload' do
      expect(market_two.reload).to have_attributes(
        status: StateMachines::MarketStateMachine::ACTIVE,
        previous_status: StateMachines::MarketStateMachine::ACTIVE
      )
    end
  end

  context 'no time range' do
    before { subject }

    it 'cancels all market bets' do
      expect(found_cancelled_bets_ids).to match_array(control_bets.map(&:id))
    end
  end

  context 'with time range' do
    subject { described_class.new.perform(payload_with_range) }

    before { subject }

    it 'cancels all market bets withing time range' do
      expect(found_cancelled_bets_ids)
        .to match_array(won_bets_in_range.map(&:id))
    end
  end

  context 'with won bets' do
    include_context 'asynchronous to synchronous'

    context 'entry requests' do
      let(:win_entry_request) { win_entry_requests.sample }
      let(:win_bet) { win_entry_request.origin }
      let(:win_cancel_comment) do
        "Cancel winnings - #{win_entry_request.amount} #{win_bet.currency} " \
        "for #{win_bet.customer} on #{win_bet.event}."
      end

      let(:placement_entry_request) { placement_entry_requests.sample }
      let(:placement_bet) { placement_entry_request.origin }
      let(:bet_cancel_comment) do
        "Cancel bet - #{placement_entry_request.amount.abs} " \
        "#{placement_bet.currency} for #{placement_bet.customer} " \
        "on #{placement_bet.event}."
      end

      let(:found_win_cancel_entry_request) do
        win_bet.entry_requests.system_bet_cancel.first
      end

      let(:found_bet_cancel_entry_request) do
        placement_bet.entry_requests.system_bet_cancel.last
      end

      it 'are created for bets' do
        expect { subject }
          .to change(EntryRequest, :count)
          .by(entry_requests.length)
      end

      it 'are created with valid attributes for bet cancellation' do
        subject
        expect(found_bet_cancel_entry_request).to have_attributes(
          amount: placement_entry_request.amount.abs,
          currency_id: placement_entry_request.currency_id,
          comment: bet_cancel_comment
        )
      end

      it 'are created with valid attributes for winnings cancellation' do
        subject
        expect(found_win_cancel_entry_request).to have_attributes(
          amount: -win_entry_request.amount,
          currency_id: win_entry_request.currency_id,
          comment: win_cancel_comment
        )
      end
    end

    context 'entries' do
      let(:win_entry) { winnings.sample }
      let(:win_entry_wallet) { win_entry.wallet }

      let(:placement_entry) { placement_entries.sample }
      let(:placement_entry_wallet) { placement_entry.wallet }

      let(:found_win_cancel_entry) do
        win_entry.origin.entries.system_bet_cancel.first
      end

      let(:found_bet_cancel_entry) do
        placement_entry.reload.origin.entries.system_bet_cancel.last
      end

      it 'are created for won bets' do
        expect { subject }.to change(Entry, :count).by(entries.length)
      end

      it 'are created with valid attributes for bet cancellation' do
        subject
        expect(found_bet_cancel_entry).to have_attributes(
          amount: placement_entry.amount.abs,
          wallet_id: placement_entry_wallet.id
        )
      end

      it 'are created with valid attributes for winnings cancellation' do
        subject
        expect(found_win_cancel_entry).to have_attributes(
          amount: -win_entry.amount,
          wallet_id: win_entry_wallet.id
        )
      end
    end
  end

  context 'invalid payload' do
    context 'without event id' do
      let(:payload) do
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
        '<bet_cancel timestamp="1234000">'\
        '<market specifiers="gamenr=1|pointnr=20" id="520"/>'\
        '</bet_cancel>'
      end

      it 'raises an error' do
        expect { subject }.to raise_error(OddsFeed::InvalidMessageError)
      end
    end

    context 'without markets' do
      let(:payload) do
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
        '<bet_cancel event_id="sr:match:4711" timestamp="1234000">'\
        '</bet_cancel>'
      end

      it 'raises an error' do
        expect { subject }.to raise_error(OddsFeed::InvalidMessageError)
      end
    end
  end
end
