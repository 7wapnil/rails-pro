describe Withdrawals::WithdrawalService do
  subject(:service) do
    described_class.new(entry_request: entry_request)
  end

  let(:currency) { create(:currency, :with_withdrawal_rule) }
  let(:withdraw_amount) { 50 }
  let(:balance_amount) { 200 }
  let(:customer) { create(:customer) }
  let(:wallet) { create(:wallet, customer: customer, currency: currency) }
  let(:entry_request) do
    create(:entry_request, :withdraw,
           amount: withdraw_amount,
           customer: customer,
           currency: currency)
  end
  let(:entry) do
    create(:entry,
           currency: currency,
           customer: customer,
           kind: EntryRequest::WITHDRAW)
  end
  let!(:balance) do
    create(:balance, :real_money, amount: balance_amount, wallet: wallet)
  end

  context 'authorize entry request' do
    include_context 'frozen_time'

    before do
      allow(WalletEntry::AuthorizationService).to receive(:call) { entry }
      service.call
    end

    it 'passes entry request to WalletEntry::AuthorizationService' do
      expect(WalletEntry::AuthorizationService)
        .to have_received(:call)
        .with(entry_request).once
    end

    it 'saves authorization date to entry' do
      expect(entry.authorized_at).to eq(Time.zone.now)
    end
  end

  it 'subtract withdrawal amount from customer balance amount' do
    service.call

    expect(balance.reload.amount).to eq(balance_amount - withdraw_amount)
  end
end
