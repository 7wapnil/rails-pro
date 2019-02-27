# frozen_string_literal: true

describe EntryRequests::RefundService do
  subject(:service) { described_class.new(entry_request: refund_request) }

  let(:currency) { create(:currency, :with_refund_rule) }
  let(:wallet) { create(:wallet, currency: currency) }
  let(:refund_amount) { 10 }
  let(:balance_amount) { 140 }
  let!(:balance) do
    create(:balance,
           :real_money,
           wallet: wallet,
           amount: balance_amount)
  end
  let(:refund_request) do
    create(:entry_request,
           :refund,
           customer: wallet.customer,
           currency: currency,
           amount: refund_amount)
  end

  context 'request authorization' do
    before do
      allow(WalletEntry::AuthorizationService).to receive(:call)
      service.call
    end

    it 'passes entry request to the WalletEntry::AuthorizationService' do
      expect(WalletEntry::AuthorizationService)
        .to have_received(:call)
        .with(refund_request)
    end
  end

  context 'when success' do
    it 'updates balance amount' do
      service.call
      expect(balance.reload.amount).to eq(balance_amount + refund_amount)
    end
  end
end
