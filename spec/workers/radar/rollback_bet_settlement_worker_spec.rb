# frozen_string_literal: true

describe Radar::RollbackBetSettlementWorker do
  subject { described_class.new.perform(payload_xml) }

  let(:payload_xml) do
    file_fixture('radar_rollback_bet_settlement_fixture.xml').read
  end
  let(:payload) { XmlParser.parse(payload_xml) }
  let(:event_id) { payload.dig('rollback_bet_settlement', 'event_id') }

  let(:control_markets) do
    [
      create(:market, :settled, external_id: "#{event_id}:123"),
      create(:market, :settled, external_id: "#{event_id}:124/score=32.2"),
      create(:market, :settled, external_id: "#{event_id}:125/total=32.2")
    ]
  end
  let!(:markets) do
    [
      *control_markets,
      create(:market, :settled, external_id: "#{event_id}:322")
    ]
  end

  let(:control_bets) do
    [
      create(:bet, :settled, :won,
             customer: build(:customer),
             odd: build(:odd, market: control_markets.first)),
      create(:bet, :settled,
             customer: build(:customer),
             odd: build(:odd, market: control_markets.first)),
      create(:bet, :settled, :won,
             customer: build(:customer),
             odd: build(:odd, market: control_markets.second))
    ]
  end
  let(:excluded_bets) do
    [
      create(:bet, :won, :settled, customer: build(:customer),
                                   odd: build(:odd, market: markets.last)),
      create(:bet, :rejected, customer: build(:customer),
                              odd: build(:odd, market: control_markets.first)),
      create(:bet, :cancelled, customer: build(:customer),
                               odd: build(:odd, market: control_markets.first))
    ]
  end
  let!(:bets) { [*control_bets, *excluded_bets] }
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

  let(:control_entry_requests) do
    [
      create(:entry_request, :win, :internal,
             origin: bets.first,
             initiator: bets.first.customer,
             customer: bets.first.customer,
             currency: bets.first.currency),
      create(:entry_request, :win, :internal,
             origin: bets.third,
             initiator: bets.third.customer,
             customer: bets.third.customer,
             currency: bets.third.currency)
    ]
  end
  let!(:entry_requests) do
    [
      *control_entry_requests,
      create(:entry_request, :bet, :internal,
             origin: bets.second,
             initiator: bets.second.customer,
             customer: bets.second.customer,
             currency: bets.second.currency),
      create(:entry_request, :win, :internal,
             origin: bets.last,
             initiator: bets.last.customer,
             customer: bets.last.customer,
             currency: bets.last.currency)
    ]
  end
  let!(:entries) do
    entry_requests.map do |request|
      wallet = Wallet.find_by(currency: request.currency,
                              customer: request.customer)
      create(:entry, kind: request.kind,
                     origin: request.origin,
                     amount: request.amount,
                     entry_request: request,
                     wallet: wallet)
    end
  end

  let!(:rollback_entry_currency_rules) do
    control_entry_requests.map do |entry_request|
      create(:entry_currency_rule,
             currency: entry_request.currency,
             min_amount: -10_000,
             max_amount: 10_000,
             kind: EntryKinds::ROLLBACK)
    end
  end

  include_context 'base_currency'

  context 'market statuses' do
    let(:active_market_ids) do
      markets.select { |market| market.reload.active? }.map(&:id)
    end

    before { subject }

    it 'are reverted only for markets according to payload' do
      expect(active_market_ids).to eq(control_markets.map(&:id))
    end

    it 'are reverted from previous statuses' do
      expect(control_markets.sample.reload).to have_attributes(
        status: StateMachines::MarketStateMachine::ACTIVE,
        previous_status: nil
      )
    end

    it 'are not updated for markets not in payload' do
      expect(markets.last.reload).to have_attributes(
        status: StateMachines::MarketStateMachine::SETTLED,
        previous_status: StateMachines::MarketStateMachine::ACTIVE
      )
    end
  end

  context 'money' do
    let(:win_entry_request) { control_entry_requests.sample }
    let(:win_bet) { win_entry_request.origin }

    include_context 'asynchronous to synchronous'

    it 'creates rollback entries for won bets' do
      expect { subject }
        .to change(Entry, :count)
        .by(control_entry_requests.length)
    end

    context 'bonus rollover' do
      before do
        control_bets.each do |bet|
          customer_bonus = create(:customer_bonus,
                                  customer: bet.customer,
                                  wallet: bet.customer.wallets.first)

          customer_bonus.bets << bet
        end
      end

      it 'calls rollover bonus service' do
        expect(CustomerBonuses::RollbackBonusRolloverService)
          .to receive(:call)
          .exactly(control_bets.count).times

        subject
      end
    end

    context 'entry requests' do
      let(:comment) do
        "Rollback won amount #{win_entry_request.amount} #{win_bet.currency}" \
        " for #{win_bet.customer} on #{win_bet.event}."
      end

      let(:found_rollback_entry_request) do
        EntryRequest.find_by(origin: win_bet, kind: EntryKinds::ROLLBACK)
      end

      it 'are created for won bets' do
        expect { subject }
          .to change(EntryRequest, :count)
          .by(control_entry_requests.length)
      end

      it 'are created with valid attributes' do
        subject
        expect(found_rollback_entry_request).to have_attributes(
          amount: -win_entry_request.amount,
          currency_id: win_entry_request.currency_id,
          comment: comment
        )
      end
    end

    context 'entries' do
      let(:win_entry) { win_entry_request.entry }
      let(:wallet) { win_entry.wallet }

      let(:found_rollback_entry) do
        Entry.find_by(origin: win_entry.origin, kind: EntryKinds::ROLLBACK)
      end

      it 'are created for won bets' do
        expect { subject }
          .to change(Entry, :count)
          .by(control_entry_requests.length)
      end

      it 'are created with valid attributes' do
        subject
        expect(found_rollback_entry).to have_attributes(
          amount: -win_entry.amount,
          wallet_id: wallet.id
        )
      end
    end
  end

  context 'bets statuses' do
    let(:accepted_bets_ids) do
      bets.select { |market| market.reload.accepted? }.map(&:id)
    end

    before { subject }

    it 'are reverted only for bets related to markets from payload' do
      expect(accepted_bets_ids).to eq(control_bets.map(&:id))
    end

    it 'are reverted to ACCEPTED' do
      expect(control_bets.sample.reload).to have_attributes(
        status: StateMachines::BetStateMachine::ACCEPTED,
        settlement_status: nil
      )
    end

    it 'are not updated for another bets' do
      expect(excluded_bets.sample.reload.status)
        .not_to eq(StateMachines::BetStateMachine::ACCEPTED)
    end
  end
end
