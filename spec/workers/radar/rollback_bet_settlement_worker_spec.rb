# frozen_string_literal: true

describe Radar::RollbackBetSettlementWorker do
  subject { described_class.new.perform(payload_xml) }

  let(:payload_xml) do
    file_fixture('radar_rollback_bet_settlement_fixture.xml').read
  end
  let(:payload) { XmlParser.parse(payload_xml) }
  let(:event_id) { payload.dig('rollback_bet_settlement', 'event_id') }
  let(:event) { Event.find_by(external_id: event_id) }
  let(:timestamp) { payload.dig('rollback_bet_settlement', 'timestamp') }
  let(:message_producer) { payload.dig('rollback_bet_settlement', 'product') }

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

  include_context 'base_currency'
  include_context 'asynchronous to synchronous'

  context 'general cases' do
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
               odd: build(:odd, market: control_markets.second)),
        create(:bet, :settled, :voided,
               customer: build(:customer),
               odd: build(:odd, market: control_markets.first))
      ]
    end
    let(:excluded_bets) do
      [
        create(:bet, :won, :settled,
               customer: build(:customer),
               odd: build(:odd, market: markets.last)),
        create(:bet, :rejected,
               customer: build(:customer),
               odd: build(:odd, market: control_markets.first)),
        create(:bet, :cancelled,
               customer: build(:customer),
               odd: build(:odd, market: control_markets.first)),
        create(:bet, :settled, :voided,
               customer: build(:customer),
               odd: build(:odd, market: markets.last))
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
               origin: control_bets.first,
               initiator: control_bets.first.customer,
               customer: control_bets.first.customer,
               currency: control_bets.first.currency),
        create(:entry_request, :win, :internal,
               origin: control_bets.third,
               initiator: control_bets.third.customer,
               customer: control_bets.third.customer,
               currency: control_bets.third.currency),
        create(:entry_request, :refund, :internal,
               origin: control_bets.fourth,
               initiator: control_bets.fourth.customer,
               customer: control_bets.fourth.customer,
               currency: control_bets.fourth.currency)
      ]
    end
    let!(:entry_requests) do
      [
        *control_entry_requests,
        create(:entry_request, :bet, :internal,
               origin: control_bets.second,
               initiator: control_bets.second.customer,
               customer: control_bets.second.customer,
               currency: control_bets.second.currency),
        create(:entry_request, :win, :internal,
               origin: excluded_bets.last,
               initiator: excluded_bets.last.customer,
               customer: excluded_bets.last.customer,
               currency: excluded_bets.last.currency)
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

    context 'writes logs' do
      before do
        allow(Rails.logger).to receive(:info)
        allow_any_instance_of(described_class)
          .to receive(:job_id)
                .and_return(123)
        described_class.new.perform(payload_xml)
      end

      it 'logs extra data' do
        expect(Rails.logger)
          .to have_received(:info)
                .with(
                  hash_including(
                    event_id: event_id,
                    event_producer_id: event&.producer_id,
                    message_producer_id: message_producer,
                    message_timestamp: timestamp
                  )
                )
      end
    end

    context 'market statuses' do
      let(:active_market_ids) do
        markets.select { |market| market.reload.active? }.map(&:id)
      end

      it 'are reverted only for markets according to payload' do
        subject
        expect(active_market_ids).to eq(control_markets.map(&:id))
      end

      it 'are reverted from previous statuses' do
        subject
        expect(control_markets.sample.reload).to have_attributes(
          status: StateMachines::MarketStateMachine::ACTIVE,
          previous_status: nil
        )
      end

      it 'are not updated for markets not in payload' do
        subject
        expect(markets.last.reload).to have_attributes(
          status: StateMachines::MarketStateMachine::SETTLED,
          previous_status: StateMachines::MarketStateMachine::ACTIVE
        )
      end

      context 'on rollback status transition error' do
        let(:logger_class) { ::OddsFeed::Radar::RollbackBetSettlementHandler }
        let(:control_market) { control_markets.first }
        let(:control_bet) { control_bets.first }

        let(:error_message) do
          'There is no status snapshot for market ' \
          "#{control_market.external_id}!"
        end

        before do
          allow_any_instance_of(logger_class).to receive(:log_job_message)

          control_market.update(previous_status: nil)
        end

        it 'logs an error' do
          expect_any_instance_of(logger_class)
            .to receive(:log_job_message)
            .with(:error, message: 'Market rollback settlement error',
                          market_id: control_market.external_id,
                          status: control_market.status,
                          previous_status: control_market.previous_status,
                          reason: error_message)

          subject
        end

        it 'does not stop processing markets' do
          subject
          expect(active_market_ids)
            .to eq(control_markets.tap(&:shift).map(&:id))
        end

        it 'does not stop processing bets' do
          subject
          expect(control_bet.reload).to have_attributes(
            void_factor: nil,
            status: StateMachines::BetStateMachine::ACCEPTED,
            settlement_status: nil
          )
        end
      end
    end

    context 'money' do
      let(:settlement_entry_request) { control_entry_requests.last }
      let(:settled_bet) { settlement_entry_request.origin }

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
        let(:win_comment) do
          "Rollback won amount #{settlement_entry_request.amount} " \
          "#{settled_bet.currency} for #{settled_bet.customer} on " \
          "#{settled_bet.event}."
        end
        let(:voided_comment) do
          "Rollback bet refund #{settlement_entry_request.amount} " \
          "#{settled_bet.currency} for #{settled_bet.customer} on " \
          "#{settled_bet.event}."
        end
        let(:comment) { settled_bet.won? ? win_comment : voided_comment }

        let(:found_rollback_entry_request) do
          EntryRequest.find_by(origin: settled_bet, kind: EntryKinds::ROLLBACK)
        end

        it 'are created for settled bets' do
          expect { subject }
            .to change(EntryRequest, :count)
            .by(control_entry_requests.length)
        end

        it 'are created with valid attributes' do
          subject
          expect(found_rollback_entry_request).to have_attributes(
            amount: -settlement_entry_request.amount,
            currency_id: settlement_entry_request.currency_id,
            comment: comment
          )
        end
      end

      context 'entries' do
        let(:settlement_entry) { settlement_entry_request.entry }
        let(:wallet) { settlement_entry.wallet }

        let(:found_rollback_entry) do
          Entry.find_by(origin: settlement_entry.origin,
                        kind: EntryKinds::ROLLBACK)
        end

        it 'are created for settled bets' do
          expect { subject }
            .to change(Entry, :count)
            .by(control_entry_requests.length)
        end

        it 'are created with valid attributes' do
          subject
          expect(found_rollback_entry).to have_attributes(
            amount: -settlement_entry.amount,
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
          void_factor: nil,
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

  context 'on pending manual settlement bet' do
    let(:pending_settlement_bet) do
      create(:bet, :pending_manual_settlement,
             customer: build(:customer),
             odd: build(:odd, market: control_markets.first))
    end
    let(:wallet) do
      create(:wallet, customer: pending_settlement_bet.customer,
                      currency: pending_settlement_bet.currency)
    end
    let!(:balance) do
      create(:balance, :real_money, amount: 10_000, wallet: wallet)
    end

    it 'is reverted to ACCEPTED' do
      subject
      expect(pending_settlement_bet.reload).to have_attributes(
        void_factor: nil,
        status: StateMachines::BetStateMachine::ACCEPTED,
        settlement_status: nil
      )
    end

    it 'does not create entry requests' do
      expect { subject }.not_to change(EntryRequest, :count)
    end

    it 'does not create entries' do
      expect { subject }.not_to change(Entry, :count)
    end
  end
end
