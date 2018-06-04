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
          kind: Entry.kinds[:deposit],
          amount: 29.99,
          currency: Wallet.currencies[:euro]
        }
      )
    end

    it 'should create a wallet' do
      assert_equal Wallet.where(customer_id: customer.id).count, 0
      WalletEntryService.call(request.id)
      assert_equal Wallet.where(customer_id: customer.id).count, 1
    end

    it 'should create a real money balance' do
      assert_equal Balance.count, 0
      WalletEntryService.call(request.id)
      balance = Balance
                  .joins(:wallet)
                  .where('wallets.customer_id': customer.id)
                  .first

      assert balance != nil
      assert_equal Balance.kinds[balance.kind], Balance.kinds[:real_money]
      assert_equal balance.amount, request.payload['amount']
    end

    it 'should create a wallet entry' do
      assert_equal Entry.count, 0
      WalletEntryService.call(request.id)
      entry = Entry
                  .joins(:wallet)
                  .where('wallets.customer_id': customer.id)
                  .first

      assert entry != nil
      assert_equal entry.amount, request.payload['amount']
    end

    it 'should create balance entry record' do
      assert_equal BalanceEntry.count, 0
      WalletEntryService.call(request.id)
      wallet = Wallet.find_by(customer_id: customer.id)
      entry = Entry.find_by(wallet_id: wallet.id)
      balance_entry = BalanceEntry.where(entry_id: entry.id).first
      assert balance_entry != nil
      assert_equal balance_entry.amount, request.payload['amount']
    end

    it 'should add entry amount into wallet' do
      WalletEntryService.call(request.id)
      wallet = Wallet.find_by(customer_id: customer.id)
      assert_equal wallet.amount, request.payload['amount']
    end
  end
end
