describe Withdrawals::WithdrawalService do
  subject(:service) { described_class.new(wallet, withdraw_amount) }

  let(:currency) { create(:currency, :with_withdrawal_rule) }
  let(:withdraw_amount) { 50 }
  let(:balance_amount) { 200 }
  let(:customer) { create(:customer) }
  let(:wallet) { create(:wallet, customer: customer, currency: currency) }
  let!(:balance) do
    create(:balance, :real_money, amount: balance_amount, wallet: wallet)
  end

  context 'withdraw verification' do
    before do
      allow(Withdrawals::WithdrawalVerification).to receive(:call)
      service.call
    end

    it 'passes wallet and amount to withdrawal verification service' do
      expect(Withdrawals::WithdrawalVerification)
        .to have_received(:call)
        .with(wallet, withdraw_amount).once
    end
  end

  context 'build entry request' do
    before do
      request = create(:entry_request, :withdraw, currency: currency)
      allow(Withdrawals::WithdrawalRequestBuilder).to receive(:call) { request }
      service.call
    end

    it 'passes wallet and amount to WithdrawalRequestBuilder' do
      expect(Withdrawals::WithdrawalRequestBuilder)
        .to have_received(:call)
        .with(wallet, withdraw_amount).once
    end
  end

  context 'authorize created entry request' do
    let(:request) { create(:entry_request) }

    before do
      allow(Withdrawals::WithdrawalRequestBuilder).to receive(:call) { request }
      allow(WalletEntry::AuthorizationService).to receive(:call)
      service.call
    end

    it 'passes created entry request to WalletEntry::AuthorizationService' do
      expect(WalletEntry::AuthorizationService)
        .to have_received(:call)
        .with(request).once
    end
  end

  context "can't withdraw money" do
    let(:withdraw_error) { Withdrawals::WithdrawalError }

    it 'raises error when customer has active bonus' do
      allow(customer).to receive(:active_bonus) { create(:customer_bonus) }

      expect { service.call }.to raise_error withdraw_error
    end

    it 'raises error when withdraw amount is more than balance amount' do
      expect { described_class.call(wallet, balance_amount + 1) }
        .to raise_error(withdraw_error)
    end
  end

  it 'subtract withdrawal amount from customer balance amount' do
    service.call

    expect(balance.reload.amount).to eq(balance_amount - withdraw_amount)
  end
end
