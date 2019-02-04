# frozen_string_literal: true

describe EntryRequests::BetSettlementService do
  subject { described_class.call(entry_request: entry_request) }

  let(:entry_request) { build(:entry_request, origin: bet) }

  before do
    allow(::WalletEntry::AuthorizationService).to receive(:call)
  end

  context 'entry request with pending bet' do
    let(:bet) { create(:bet) }

    it 'is not proceeded' do
      expect { subject }
        .to raise_error(
          ArgumentError,
          'Entry request for settled bet is expected!'
        )
    end
  end

  context 'entry request with bet that can be settled' do
    let(:bet) { create(:bet, :settled, :won) }

    it 'is proceeded' do
      expect(::WalletEntry::AuthorizationService)
        .to receive(:call)
        .with(entry_request)

      subject
    end
  end
end
