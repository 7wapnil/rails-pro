# frozen_string_literal: true

describe Bets::Settle do
  subject do
    described_class.call(bet: bet, void_factor: void_factor, result: result)
  end

  let!(:bet) { create(:bet, :accepted) }
  let(:void_factor) {}
  let(:result) { '0' }
  let(:last_entry_request) { EntryRequest.order(created_at: :desc).first }
  let(:last_entry) { Entry.order(created_at: :desc).first }
  let!(:primary_currency) { create(:currency, :primary) }

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

  context 'when settled bet has been passed' do
    let!(:bet) { create(:bet, :with_placement_entry, :settled) }

    it 'raises an error' do
      expect { subject }.to raise_error('Bet is not accepted')
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

  context 'when rejected bet has been passed' do
    let!(:bet) { create(:bet, :rejected) }

    it 'raises an error' do
      expect { subject }.to raise_error('Bet is not accepted')
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
