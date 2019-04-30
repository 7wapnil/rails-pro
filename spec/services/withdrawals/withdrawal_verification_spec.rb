describe Withdrawals::WithdrawalVerification do
  subject(:service) { described_class.new(wallet, withdraw_amount) }

  let(:wallet) { instance_double(Wallet) }
  let(:customer) { instance_double(Customer) }
  let(:withdraw_amount) { 50 }
  let(:balance) { instance_double(Balance, amount: withdraw_amount + 100) }

  before do
    allow(wallet).to receive(:real_money_balance).and_return(balance)
    allow(wallet).to receive(:customer).and_return(customer)
    allow(customer).to receive(:active_bonus).and_return(nil)
  end

  context 'successfully verify withdraw' do
    it 'do not raise errors' do
      expect { service.call }.not_to raise_error
    end
  end

  context 'raise WithdrawalError' do
    let(:bonus) { instance_double(CustomerBonus) }
    let(:error_class) { Withdrawals::WithdrawalError }
    let(:not_enough_money_msg) do
      Withdrawals::WithdrawalVerification::NOT_ENOUGH_MONEY
    end
    let(:bonus_exists_msg) do
      Withdrawals::WithdrawalVerification::ACTIVE_BONUS_EXISTS
    end

    it 'raises error when wallet amount is less than withdrawal amount' do
      invalid_balance = instance_double(Balance, amount: withdraw_amount - 10)
      allow(wallet).to receive(:real_money_balance).and_return(invalid_balance)

      expect { service.call }.to raise_error(error_class, not_enough_money_msg)
    end
  end
end
