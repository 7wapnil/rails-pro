# frozen_string_literal: true

describe EntryRequests::Factories::BetSettlement do
  let(:service_result) { subject.call }

  describe 'initialize' do
    subject(:bet_settlement) { described_class.new(bet: bet) }

    let(:bet) { create(:bet) }

    it 'stores bet value' do
      expect(subject.instance_variable_get(:@bet)).to eq(bet)
    end
  end

  context 'with entire win bet' do
    subject(:bet_settlement) { described_class.new(bet: bet) }

    let(:bet) { create(:bet, :settled, :won) }
    let(:win_entry_request) { service_result.first }

    let(:win_entry_request_attributes) do
      {
        currency: bet.currency,
        kind: 'win',
        mode: EntryRequest::SYSTEM,
        initiator: bet.customer,
        customer: bet.customer,
        origin: bet
      }
    end

    before { service_result }

    it 'returns array with win entry request' do
      expect(service_result).to eq([win_entry_request])
    end

    it 'creates win entry request of correct type' do
      expect(win_entry_request).to be_an EntryRequest
    end

    it 'creates win entry request with correct params' do
      expect(win_entry_request)
        .to have_attributes(win_entry_request_attributes)
    end

    it 'creates win entry request with amount in predictable range' do
      expect(win_entry_request.amount)
        .to be_within(0.01).of(bet.win_amount)
    end
  end

  context 'half win bet, half refund' do
    subject(:bet_settlement) { described_class.new(bet: bet) }

    let(:bet) { create(:bet, :settled, :won, void_factor: 0.5) }
    let(:refund_entry_request) { service_result.last }
    let(:win_entry_request) { service_result.first }

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

    let(:win_entry_request_attributes) do
      {
        currency: bet.currency,
        kind: 'win',
        mode: EntryRequest::SYSTEM,
        initiator: bet.customer,
        customer: bet.customer,
        origin: bet
      }
    end

    before { service_result }

    it 'returns array with win and refund entry request' do
      expect(service_result).to eq([win_entry_request, refund_entry_request])
    end

    it 'creates win entry request of correct type' do
      expect(win_entry_request).to be_an EntryRequest
    end

    it 'creates win entry request with correct params' do
      expect(win_entry_request)
        .to have_attributes(win_entry_request_attributes)
    end

    it 'creates win entry request with amount in predictable range' do
      expect(win_entry_request.amount)
        .to be_within(0.01).of(bet.win_amount)
    end

    it 'creates refund entry request of correct type' do
      expect(refund_entry_request).to be_an EntryRequest
    end

    it 'creates refund entry request with correct params' do
      expect(refund_entry_request)
        .to have_attributes(refund_entry_request_attributes)
    end

    it 'creates refund entry request with amount in predictable range' do
      expect(refund_entry_request.amount)
        .to be_within(0.01).of(bet.refund_amount)
    end
  end

  context 'bet lose, half refund' do
    subject(:bet_settlement) { described_class.new(bet: bet) }

    let(:bet) { create(:bet, :settled, :lost, void_factor: 0.5) }
    let(:refund_entry_request) { service_result.last }

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

    before { service_result }

    it 'returns array with win entry request' do
      expect(service_result).to eq([refund_entry_request])
    end

    it 'creates refund entry request of correct type' do
      expect(refund_entry_request).to be_an EntryRequest
    end

    it 'creates refund entry request with correct params' do
      expect(refund_entry_request)
        .to have_attributes(refund_entry_request_attributes)
    end

    it 'creates refund entry request with amount in predictable range' do
      expect(refund_entry_request.amount)
        .to be_within(0.01).of(bet.refund_amount)
    end
  end
end
