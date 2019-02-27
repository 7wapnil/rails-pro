describe Withdrawals::WithdrawalRejectionService do
  subject(:service) { described_class.new(entry.id) }

  let(:entry) { create(:entry, kind: EntryRequest::WITHDRAW) }

  context 'success' do
    let(:refund_request) { create(:entry_request, kind: EntryRequest::REFUND) }

    before do
      allow(EntryRequests::Factories::Refund)
        .to receive(:call)
        .and_return(refund_request)

      allow(EntryRequests::RefundWorker)
        .to receive(:perform_async)
        .and_call_original

      service.call
    end

    it 'handles refund entry request asynchronously' do
      expect(EntryRequests::RefundWorker)
        .to have_received(:perform_async)
        .with(refund_request.id)
    end
  end
end
