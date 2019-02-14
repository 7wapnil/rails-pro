# frozen_string_literal: true

describe Bets::Settlement::Proceed do
  subject { described_class.call(bet: bet) }

  let(:bet) { create(:bet, :settled) }
  let(:last_entry_request) { EntryRequest.order(created_at: :desc).first }

  before { allow(EntryRequests::BetSettlementService).to receive(:call) }

  context 'with entire win bet' do
    let(:bet) { create(:bet, :settled, :won) }

    let(:win_entry_request_attributes) do
      {
        currency: bet.currency,
        kind: EntryKinds::WIN,
        mode: EntryRequest::SYSTEM,
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

    it 'calls service for proceeding entry request' do
      expect(EntryRequests::BetSettlementWorker).to receive(:perform_async)
      subject
    end
  end

  context 'half win bet, half refund' do
    let(:bet) { create(:bet, :settled, :won, void_factor: 0.5) }

    let(:win_entry_request_attributes) do
      {
        currency: bet.currency,
        kind: EntryKinds::WIN,
        mode: EntryRequest::SYSTEM,
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
      expect(last_entry_request.amount)
        .to be_within(0.01).of(bet.win_amount)
    end

    it 'calls service for proceeding entry request' do
      expect(EntryRequests::BetSettlementWorker).to receive(:perform_async)
      subject
    end
  end

  context 'bet lose, half refund' do
    let(:bet) { create(:bet, :settled, :lost, void_factor: 0.5) }

    let(:refund_entry_request_attributes) do
      {
        currency: bet.currency,
        kind: 'refund',
        mode: EntryRequest::SYSTEM,
        initiator: bet.customer,
        customer: bet.customer,
        origin: bet
      }
    end

    it 'creates only one entry request' do
      expect { subject }.to change(EntryRequest, :count).by(1)
    end

    it 'creates entry request with refund params' do
      subject
      expect(last_entry_request)
        .to have_attributes(refund_entry_request_attributes)
    end

    it 'creates entry request with amount in predictable range' do
      subject
      expect(last_entry_request.amount)
        .to be_within(0.01).of(bet.refund_amount)
    end

    it 'calls service for proceeding entry request' do
      expect(EntryRequests::BetSettlementWorker).to receive(:perform_async)
      subject
    end
  end

  context 'bet lose, without refund' do
    let(:bet) { create(:bet, :settled, :lost) }

    it 'does not create entry request' do
      expect { subject }.not_to change(EntryRequest, :count)
    end

    it 'does not call service for proceeding entry request' do
      expect(EntryRequests::BetSettlementWorker).not_to receive(:perform_async)
      subject
    end
  end
end
