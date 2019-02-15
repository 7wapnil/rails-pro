describe Withdrawals::InitiateWithdrawalService do
  subject(:service) do
    described_class.new(wallet: wallet, amount: withdraw_amount)
  end

  let(:currency) { create(:currency, :with_withdrawal_rule) }
  let(:withdraw_amount) { 50 }
  let(:balance_amount) { 250 }
  let(:customer) { create(:customer) }
  let(:wallet) { create(:wallet, customer: customer, currency: currency) }
  let!(:balance) do
    create(:balance, :real_money, amount: balance_amount, wallet: wallet)
  end

  context 'withdrawal initiation flow' do
    before do
      allow(Withdrawals::WithdrawalVerification).to receive(:call)
      allow(EntryRequests::Factories::Withdraw).to receive(:call)
      service.call
    end

    it 'passes wallet and amount to withdrawal verification service' do
      expect(Withdrawals::WithdrawalVerification)
        .to have_received(:call)
        .with(wallet, withdraw_amount).once
    end

    it 'passes wallet and amount to withdrawal factory' do
      expect(EntryRequests::Factories::Withdraw)
        .to have_received(:call)
        .with(wallet: wallet,
              amount: withdraw_amount,
              mode: EntryRequest::CASHIER)
    end
  end

  context 'when success' do
    let(:created_request) { service.call }
    let(:entry_request) { create(:entry_request) }

    before do
      allow(EntryRequests::Factories::Withdraw)
        .to receive(:call)
        .and_return(entry_request)
    end

    it 'returns created entry request' do
      expect(created_request).to eq(entry_request)
    end
  end

  context 'when error' do
    let(:withdraw_error) { Withdrawals::WithdrawalError }

    it 'raises error when customer has active bonus' do
      bonus = create(:customer_bonus)
      allow_any_instance_of(Customer).to receive(:active_bonus) { bonus }

      expect { service.call }.to raise_error withdraw_error
    end

    it 'raises error when withdraw.amount > balance.amount' do
      balance.update_attributes(amount: withdraw_amount - 1)

      expect { service.call }.to raise_error(withdraw_error)
    end
  end
end
