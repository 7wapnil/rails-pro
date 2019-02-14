# frozen_string_literal: true

describe EntryRequests::BetSettlementService do
  subject { described_class.call(entry_request: entry_request) }

  let(:entry_request) { create(:entry_request, origin: bet) }

  before do
    allow(::WalletEntry::AuthorizationService).to receive(:call)
  end

  context 'entry request with pending bet' do
    let(:bet) { create(:bet) }

    let(:error_message) do
      I18n.t('errors.messages.entry_request_for_settled_bet', bet_id: bet.id)
    end

    before { subject }

    it 'is not proceeded' do
      expect(entry_request).to have_attributes(
        status: EntryRequest::FAILED,
        result: { 'message' => error_message }
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

  context 'with failed entry request' do
    let(:entry_request) do
      create(:entry_request, origin: bet, status: EntryRequest::FAILED)
    end

    it "doesn't proceed" do
      expect(WalletEntry::AuthorizationService).not_to receive(:call)
    end
  end
end
