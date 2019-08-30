# frozen_string_literal: true

describe Radar::RollbackBetCancelWorker do
  subject { described_class.new.perform(payload) }

  let(:pending_status) { StateMachines::BetStateMachine::VALIDATED_INTERNALLY }
  let(:cancelled_status) { StateMachines::BetStateMachine::CANCELLED_BY_SYSTEM }

  let(:payload) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
    '<rollback_bet_cancel event_id="sr:match:1234" timestamp="1234000">'\
    '<market specifiers="gamenr=1|pointnr=20" id="1"/>'\
    '<market id="2"/>'\
    '</rollback_bet_cancel>'
  end

  let(:event) { create(:event, external_id: 'sr:match:1234') }
  let(:settled_market) do
    create(:market,
           previous_status: StateMachines::MarketStateMachine::SETTLED,
           status: StateMachines::MarketStateMachine::CANCELLED,
           event: event,
           external_id: 'sr:match:1234:1/gamenr=1|pointnr=20')
  end
  let(:active_market) do
    create(:market, status: StateMachines::MarketStateMachine::CANCELLED,
                    event: event,
                    external_id: 'sr:match:1234:2')
  end
  let(:excluded_market) do
    create(:market,
           previous_status: StateMachines::MarketStateMachine::SETTLED,
           status: StateMachines::MarketStateMachine::CANCELLED,
           event: event,
           external_id: 'sr:match:1234:1')
  end

  let(:won_bets) do
    create_list(:bet, rand(1..3), :won,
                odd: build(:odd, market: settled_market),
                status: pending_status,
                customer: build(:customer))
  end
  let(:common_bets) do
    create_list(:bet, rand(1..3),
                odd: build(:odd, market: active_market),
                status: StateMachines::BetStateMachine::CANCELLED_BY_SYSTEM,
                customer: build(:customer))
  end
  let(:excluded_win_bet) do
    create(:bet, :won,
           odd: build(:odd, market: excluded_market),
           status: StateMachines::BetStateMachine::CANCELLED_BY_SYSTEM,
           customer: build(:customer))
  end
  let(:excluded_placement_bet) do
    create(:bet, odd: build(:odd, market: excluded_market),
                 status: StateMachines::BetStateMachine::CANCELLED_BY_SYSTEM,
                 customer: build(:customer))
  end
  let(:excluded_bets) { [excluded_win_bet, excluded_placement_bet] }
  let!(:bets) { [*won_bets, *common_bets, *excluded_bets] }

  let!(:wallets) do
    bets.map do |bet|
      create(:wallet, customer: bet.customer, currency: bet.currency)
    end
  end
  let!(:balances) do
    wallets.map do |wallet|
      create(:balance, :real_money, amount: 10_000, wallet: wallet)
    end
  end

  let(:win_entry_requests) do
    won_bets.map do |bet|
      create(:entry_request, :system_bet_cancel, :internal,
             amount: -bet.amount,
             origin: bet,
             initiator: bet.customer,
             customer: bet.customer,
             currency: bet.currency)
    end
  end
  let(:placement_entry_requests) do
    [*won_bets, *common_bets].map do |bet|
      create(:entry_request, :system_bet_cancel, :internal,
             amount: bet.amount,
             origin: bet,
             initiator: bet.customer,
             customer: bet.customer,
             currency: bet.currency)
    end
  end
  let(:excluded_entry_requests) do
    [
      create(:entry_request, :system_bet_cancel, :internal,
             amount: -excluded_win_bet.amount,
             origin: excluded_win_bet,
             initiator: excluded_win_bet.customer,
             customer: excluded_win_bet.customer,
             currency: excluded_win_bet.currency),
      create(:entry_request, :system_bet_cancel, :internal,
             amount: excluded_placement_bet.amount,
             origin: excluded_placement_bet,
             initiator: excluded_placement_bet.customer,
             customer: excluded_placement_bet.customer,
             currency: excluded_placement_bet.currency)
    ]
  end
  let(:entry_requests) do
    [*win_entry_requests, *placement_entry_requests, *excluded_entry_requests]
  end

  let!(:winnings) do
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
  let!(:excluded_entries) do
    excluded_entry_requests.map do |request|
      wallet = Wallet.find_by(currency: request.currency,
                              customer: request.customer)
      create(:entry, kind: request.kind,
                     origin: request.origin,
                     amount: request.amount,
                     entry_request: request,
                     wallet: wallet)
    end
  end

  let!(:entry_currency_rules) do
    entry_requests.map do |entry_request|
      create(:entry_currency_rule,
             currency: entry_request.currency,
             min_amount: -10_000,
             max_amount: 10_000,
             kind: EntryKinds::ROLLBACK)
    end
  end

  include_context 'base_currency'

  context 'writes logs' do
    before do
      allow(Rails.logger).to receive(:info)
      allow_any_instance_of(described_class)
        .to receive(:job_id)
        .and_return(123)

      described_class.new.perform(payload)
    end

    it 'logs extra data' do
      expect(Rails.logger)
        .to have_received(:info)
        .with(
          hash_including(
            event_id: event.external_id,
            event_producer_id: event.producer_id,
            message_timestamp: '1234000'
          )
        )
    end
  end

  context 'market statuses' do
    before { subject }

    it 'are not rollbacked for previously settled markets' do
      expect(settled_market.reload).to have_attributes(
        status: StateMachines::MarketStateMachine::CANCELLED,
        previous_status: StateMachines::MarketStateMachine::SETTLED
      )
    end

    it 'are not rollbacked for previously active markets' do
      expect(active_market.reload).to have_attributes(
        status: StateMachines::MarketStateMachine::CANCELLED,
        previous_status: StateMachines::MarketStateMachine::ACTIVE
      )
    end

    it 'are not rollbacked for markets not in payload' do
      expect(excluded_market.reload).to have_attributes(
        status: StateMachines::MarketStateMachine::CANCELLED,
        previous_status: StateMachines::MarketStateMachine::SETTLED
      )
    end
  end

  context 'bets' do
    before { subject }

    it 'active become rollbacked to ACCEPTED' do
      expect(common_bets.map(&:reload)).to be_all(&:accepted?)
    end

    it 'won become rollbacked to SETTLED' do
      expect(won_bets.map(&:reload)).to be_all(&:settled?)
    end

    it 'excluded do nor become rollbacked' do
      expect(excluded_bets.map(&:reload)).to be_all(&:cancelled_by_system?)
    end
  end

  context 'calls entry creating service' do
    include_context 'asynchronous to synchronous'

    context 'and creates rollback entry requests' do
      let(:win_entry_request) { win_entry_requests.sample }
      let(:win_bet) { win_entry_request.origin }
      let(:win_cancel_comment) do
        "Rollback winning cancellation - #{win_entry_request.amount} " \
        "#{win_bet.currency} for #{win_bet.customer} on #{win_bet.event}."
      end

      let(:placement_entry_request) { placement_entry_requests.sample }
      let(:placement_bet) { placement_entry_request.origin }
      let(:bet_cancel_comment) do
        "Rollback bet cancellation - #{placement_entry_request.amount} " \
        "#{placement_bet.currency} for #{placement_bet.customer} " \
        "on #{placement_bet.event}."
      end

      let(:found_win_rollback_entry_request) do
        win_bet.entry_requests.rollback.first
      end

      let(:found_bet_rollback_entry_request) do
        placement_bet.entry_requests.rollback.last
      end

      it 'for bets' do
        expect { subject }
          .to change(EntryRequest, :count)
          .by(win_entry_requests.length + placement_entry_requests.length)
      end

      it 'with valid attributes for bet rollback' do
        subject
        expect(found_bet_rollback_entry_request).to have_attributes(
          amount: -placement_entry_request.amount,
          currency_id: placement_entry_request.currency_id,
          comment: bet_cancel_comment
        )
      end

      it 'with valid attributes for winnings rollback' do
        subject
        expect(found_win_rollback_entry_request).to have_attributes(
          amount: win_entry_request.amount,
          currency_id: win_entry_request.currency_id,
          comment: win_cancel_comment
        )
      end
    end

    context 'and creates rollback entries' do
      let(:win_entry) { winnings.sample }
      let(:win_entry_wallet) { win_entry.wallet }

      let(:placement_entry) { placement_entries.sample }
      let(:placement_entry_wallet) { placement_entry.wallet }

      let(:found_win_cancel_entry) do
        win_entry.origin.entries.rollback.first
      end

      let(:found_bet_cancel_entry) do
        placement_entry.reload.origin.entries.rollback.last
      end

      it 'for bets' do
        expect { subject }
          .to change(Entry, :count)
          .by(winnings.length + placement_entries.length)
      end

      it 'with valid attributes for bet cancellation' do
        subject
        expect(found_bet_cancel_entry).to have_attributes(
          amount: -placement_entry.amount,
          wallet_id: placement_entry_wallet.id
        )
      end

      it 'with valid attributes for winnings cancellation' do
        subject
        expect(found_win_cancel_entry).to have_attributes(
          amount: win_entry.amount,
          wallet_id: win_entry_wallet.id
        )
      end
    end
  end

  context 'invalid payload' do
    context 'without event id' do
      let(:payload) do
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
        '<rollback_bet_cancel timestamp="1234000">'\
        '<market specifiers="gamenr=1|pointnr=20" id="520"/>'\
        '</rollback_bet_cancel>'
      end

      it 'raises an error' do
        expect { subject }.to raise_error(OddsFeed::InvalidMessageError)
      end
    end

    context 'without markets' do
      let(:payload) do
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
        '<rollback_bet_cancel event_id="sr:match:4711" timestamp="1234000">'\
        '</rollback_bet_cancel>'
      end

      it 'raises an error' do
        expect { subject }.to raise_error(OddsFeed::InvalidMessageError)
      end
    end
  end
end
