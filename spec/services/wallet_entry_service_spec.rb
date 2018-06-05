describe 'WalletService', type: :service do
  context 'first entry' do
    let(:customer) do
      create(:customer)
    end

    let(:request) do
      create(
        :entry_request,
        payload: {
          customer_id: customer.id,
          kind: :deposit,
          amount: 29.99,
          currency: :euro
        }
      )
    end

    it 'creates a wallet' do
      expect(Wallet.where(customer: customer).count).to eq 0
      WalletEntry::Service.call(request)
      expect(Wallet.where(customer: customer).count).to eq 1
    end

    it 'creates a real money balance' do
      expect(Balance.count).to eq 0

      WalletEntry::Service.call(request)
      balance = Balance
                .joins(:wallet)
                .where(wallets: { customer: customer })
                .first

      expect(balance).to be_present
      expect(balance.real_money?).to be true
      expect(balance.amount).to eq request.payload.amount
    end

    it 'creates a wallet entry' do
      expect(Entry.count).to eq 0

      WalletEntry::Service.call(request)
      entry = Entry
              .joins(:wallet)
              .where('wallets.customer_id': customer.id)
              .first

      expect(entry).to be_present
      expect(entry.amount).to eq request.payload.amount
    end

    it 'creates balance entry record' do
      expect(BalanceEntry.count).to eq 0

      WalletEntry::Service.call(request)
      balance_entry = BalanceEntry
                      .joins(entry: { wallet: :customer })
                      .where(entry: { wallets: { customer: customer } })
                      .first

      expect(balance_entry).to be_present
      expect(balance_entry.amount).to eq request.payload.amount
    end

    it 'adds entry amount into wallet' do
      WalletEntry::Service.call(request)
      wallet = Wallet.find_by(customer_id: customer.id)
      expect(wallet.amount).to eq request.payload.amount
    end

    it 'updates entry request on failure' do
      expect_any_instance_of(WalletEntry::Service)
        .not_to receive(:handle_success)

      request[:payload]['currency'] = :peso
      WalletEntry::Service.call(request)

      expect(request.fail?).to be true
      expect(request.result['exception_class'])
        .to eq 'ActiveRecord::StatementInvalid'
    end

    it 'updates entry request on success' do
      expect_any_instance_of(WalletEntry::Service)
        .not_to receive(:handle_failure)

      WalletEntry::Service.call(request)

      expect(request.success?).to be true
      expect(request.result).not_to be_present
    end
  end
end
