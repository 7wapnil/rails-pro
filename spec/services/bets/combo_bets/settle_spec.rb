# frozen_string_literal: true

describe Bets::ComboBets::Settle do
  subject do
    described_class.call(bet_leg: bet_leg,
                         void_factor: void_factor,
                         result: result)
  end

  let!(:bet) do
    create(:bet, :combo_bets, :with_placement_entry, :with_bet_leg, :accepted)
  end
  let!(:bet_leg) { bet.bet_legs.first }
  let!(:won_bet_leg) { create(:bet_leg, :won, bet: bet) }
  let(:void_factor) {}
  let(:result) { '0' }
  let(:last_entry_request) { EntryRequest.order(created_at: :desc).first }
  let(:last_entry) { Entry.order(created_at: :desc).first }

  include_context 'base_currency'

  context 'with entire win bet' do
    let(:result) { described_class::WIN_RESULT }
    let(:win_entry_request_attributes) do
      {
        currency: bet.currency,
        kind: EntryKinds::WIN,
        mode: EntryRequest::INTERNAL,
        initiator: bet.customer,
        customer: bet.customer,
        origin: bet
      }
    end

    context 'with positive balance amount' do
      it 'creates only one entry request' do
        expect { subject }.to change(EntryRequest, :count).by(1)
      end

      it 'creates entry request with win params' do
        subject
        expect(last_entry_request)
          .to have_attributes(win_entry_request_attributes)
      end

      it 'creates entry request with amount in predictable range' do
        subject
        expect(last_entry_request.amount).to be_within(0.01).of(bet.win_amount)
      end

      it 'creates entry with amount in predictable range' do
        subject
        expect(last_entry.amount).to be_within(0.01).of(bet.win_amount)
      end
    end

    context 'with negative balance amount after' do
      let(:customer) { bet.placement_entry.customer }
      let(:wallet) { customer.wallet }
      let(:new_real_money_balance) { -10_000 }
      let!(:expected_amount) do
        new_real_money_balance + bet.amount * bet.odd_value
      end

      before do
        wallet.update(real_money_balance: new_real_money_balance)

        subject
      end

      it 'creates entry with amount in predictable range' do
        expect(wallet.reload.real_money_balance)
          .to be_within(0.01).of(expected_amount)
      end

      it 'settles bet' do
        expect(bet).to be_settled
      end
    end
  end

  context 'half win bet, half refund' do
    let(:void_factor) { 0.5 }

    it 'raises an error' do
      expect { subject }.to raise_error(
        ::Bets::NotSupportedError,
        'Void factor is not supported'
      )
    end

    it 'sets bet status to PENDING_MANUAL_SETTLEMENT' do
      subject
    rescue ::Bets::NotSupportedError
      expect(bet.reload.status)
        .to eq(StateMachines::BetStateMachine::PENDING_MANUAL_SETTLEMENT)
    end

    it 'does not create any entry request' do
      expect do
        subject
      rescue ::Bets::NotSupportedError
      end.not_to change(EntryRequest, :count)
    end

    it 'does not create any entry' do
      expect do
        subject
      rescue ::Bets::NotSupportedError
      end.not_to change(Entry, :count)
    end
  end

  context 'bet lose, half refund' do
    let(:void_factor) { 0.5 }

    it 'raises an error' do
      expect { subject }.to raise_error(
        ::Bets::NotSupportedError,
        'Void factor is not supported'
      )
    end

    it 'sets bet status to PENDING_MANUAL_SETTLEMENT' do
      subject
    rescue ::Bets::NotSupportedError
      expect(bet.reload.status)
        .to eq(StateMachines::BetStateMachine::PENDING_MANUAL_SETTLEMENT)
    end

    it 'does not create any entry request' do
      expect do
        subject
      rescue ::Bets::NotSupportedError
      end.not_to change(EntryRequest, :count)
    end

    it 'does not create any entry' do
      expect do
        subject
      rescue ::Bets::NotSupportedError
      end.not_to change(Entry, :count)
    end

    it 'does not call service for proceeding entry request' do
      expect(EntryRequests::BetSettlementService).not_to receive(:call)
      subject
    rescue ::Bets::NotSupportedError
    end
  end

  context 'bet lose, without refund' do
    it 'does not create entry request' do
      expect { subject }.not_to change(EntryRequest, :count)
    end

    it 'does not create any entry' do
      expect do
        subject
      rescue ::Bets::NotSupportedError
      end.not_to change(Entry, :count)
    end
  end

  context 'won bet leg when bet has another unsettled bet leg' do
    let(:result) { described_class::WIN_RESULT }
    let!(:unsettled_bet_leg) { create(:bet_leg, bet: bet) }

    it 'does not change bet status' do
      expect { subject }.not_to change(bet, :status)
    end

    it 'won bet leg' do
      subject
      expect(bet_leg).to be_won
    end

    it 'does not create entry request' do
      expect { subject }.not_to change(EntryRequest, :count)
    end

    it 'does not create any entry' do
      expect do
        subject
      rescue ::Bets::NotSupportedError
      end.not_to change(Entry, :count)
    end
  end

  context 'void bet leg when bet has another unsettled bet leg' do
    let(:void_factor) { Bets::Settle::ACTIVE_VOID_FACTOR }
    let!(:unsettled_bet_leg) { create(:bet_leg, bet: bet) }
    let(:expected_odd_value) do
      (bet.bet_legs[1].odd_value * bet.bet_legs[2].odd_value)
        .round(Bet::PRECISION)
    end

    it 'does not change bet status' do
      expect { subject }.not_to change(bet, :status)
    end

    it 'voids bet leg' do
      subject
      expect(bet_leg).to be_voided
    end

    it 'counts bet leg odd value as 1' do
      subject
      expect(bet_leg.bet.odd_value).to eq(expected_odd_value)
    end

    it 'does not create entry request' do
      expect { subject }.not_to change(EntryRequest, :count)
    end

    it 'does not create any entry' do
      expect do
        subject
      rescue ::Bets::NotSupportedError
      end.not_to change(Entry, :count)
    end
  end

  context 'lost bet when another unsettled bet leg' do
    let!(:unsettled_bet_leg) { create(:bet_leg, bet: bet) }

    it 'lost bet' do
      subject
      expect(bet).to be_lost
    end

    it 'lost bet leg' do
      subject
      expect(bet_leg).to be_lost
    end

    it 'does not create entry request' do
      expect { subject }.not_to change(EntryRequest, :count)
    end

    it 'does not create any entry' do
      expect do
        subject
      rescue ::Bets::NotSupportedError
      end.not_to change(Entry, :count)
    end
  end

  context 'when settled bet has been passed' do
    let!(:bet) do
      create(:bet, :combo_bets, :with_settled_bet_leg,
             :with_placement_entry, :settled)
    end

    it 'raises an error' do
      expect { subject }
        .to raise_error(I18n.t('errors.messages.bets.settled_bet_leg'))
    end

    it 'does not change bet status' do
      subject
    rescue StandardError
      expect(bet.reload.status).to eq(StateMachines::BetStateMachine::SETTLED)
    end

    it 'does not create any entry' do
      expect do
        subject
      rescue StandardError
      end.not_to change(Entry, :count)
    end

    it 'does not call service for settlement bonus' do
      expect(CustomerBonuses::BetSettlementService).not_to receive(:call)
      subject
    rescue StandardError
    end
  end

  context 'when error appears on last operation' do
    let!(:bet) { create(:bet, :combo_bets, :with_bet_leg, :accepted) }
    let(:result) { described_class::WIN_RESULT }

    before do
      allow(CustomerBonuses::BetSettlementService)
        .to receive(:call)
        .and_raise(StandardError, 'error')
    end

    it 'raises an error' do
      expect { subject }.to raise_error(StandardError, 'error')
    end

    it 'move bet to manual settlement' do
      subject
    rescue StandardError
      expect(bet.reload).to have_attributes(
        status: StateMachines::BetStateMachine::PENDING_MANUAL_SETTLEMENT,
        notification_message: 'error',
        notification_code: Bets::Notification::INTERNAL_SERVER_ERROR
      )
    end

    it 'does not create any entry' do
      expect do
        subject
      rescue StandardError
      end.not_to change(Entry, :count)
    end
  end

  context 'when rejected bet has been passed' do
    let!(:bet) { create(:bet, :combo_bets, :with_settled_bet_leg, :rejected) }

    it 'raises an error' do
      expect { subject }
        .to raise_error(I18n.t('errors.messages.bets.settled_bet_leg'))
    end

    it 'does not change bet status' do
      subject
    rescue StandardError
      expect(bet.reload.status).to eq(StateMachines::BetStateMachine::REJECTED)
    end

    it 'does not create any entry' do
      expect do
        subject
      rescue StandardError
      end.not_to change(Entry, :count)
    end

    it 'does not call service for settlement bonus' do
      expect(CustomerBonuses::BetSettlementService).not_to receive(:call)
      subject
    rescue StandardError
    end
  end
end
