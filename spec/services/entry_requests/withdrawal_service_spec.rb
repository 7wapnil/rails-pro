describe EntryRequests::WithdrawalService do
  subject(:service) do
    described_class.new(entry_request: entry_request)
  end

  let(:currency) { create(:currency, :with_withdrawal_rule) }
  let(:withdraw_amount) { 50 }
  let(:balance_amount) { 200 }
  let(:customer) { create(:customer) }
  let!(:wallet) do
    create(:wallet,
           amount: balance_amount,
           real_money_balance: balance_amount,
           customer: customer,
           currency: currency)
  end
  let(:entry_request) do
    create(:entry_request, :withdraw,
           amount: -withdraw_amount,
           real_money_amount: -withdraw_amount,
           customer: customer,
           currency: currency)
  end
  let(:entry) do
    create(:entry,
           real_money_amount: withdraw_amount,
           currency: currency,
           customer: customer,
           wallet: wallet,
           kind: EntryRequest::WITHDRAW)
  end

  include_context 'base_currency'

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

  context 'remove customer bonus' do
    before do
      create(:customer_bonus, customer: customer, wallet: wallet)
      wallet.update(bonus_balance: balance_amount)
    end

    it 'calls Bonus Deactivate service' do
      expect(CustomerBonuses::Deactivate).to receive(:call).with(
        bonus: customer.active_bonus,
        action: CustomerBonuses::Deactivate::CANCEL
      )

      subject.call
    end

    it 'removes customer bonus' do
      subject.call
      customer.reload

      expect(customer.customer_bonuses).not_to be_empty
    end
  end

  it 'subtract withdrawal amount from customer balance amount' do
    service.call

    expect(wallet.reload.real_money_balance)
      .to eq(balance_amount - withdraw_amount)
  end
end
