describe 'WalletService' do
  let(:currency) { create(:currency) }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }

  before do
    allow(EntryCurrencyRule).to receive(:find_by!) { rule }
    allow(Currency).to receive(:find_by!) { currency }
  end

  context 'first entry' do
    let(:request) do
      create(:entry_request)
    end

    let(:customer) do
      request.customer
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
      expect(balance.amount).to eq request.amount
    end

    it 'creates a wallet entry' do
      expect(Entry.count).to eq 0

      WalletEntry::Service.call(request)
      entry = Entry
              .joins(:wallet)
              .where('wallets.customer_id': customer.id)
              .first

      expect(entry).to be_present
      expect(entry.amount).to eq request.amount
    end

    it 'creates balance entry record' do
      expect(BalanceEntry.count).to eq 0

      WalletEntry::Service.call(request)
      balance_entry = BalanceEntry
                      .joins(entry: { wallet: :customer })
                      .where(entry: { wallets: { customer: customer } })
                      .first

      expect(balance_entry).to be_present
      expect(balance_entry.amount).to eq request.amount
    end

    it 'adds entry amount into wallet' do
      WalletEntry::Service.call(request)
      wallet = Wallet.find_by(customer_id: customer.id)
      expect(wallet.amount).to eq request.amount
    end

    it 'updates entry request on failure' do
      expect_any_instance_of(WalletEntry::Service)
        .not_to receive(:handle_success)

      request.amount = 600
      WalletEntry::Service.call(request)

      expect(request.fail?).to be true
      expect(request.result['exception_class'])
        .to eq 'ActiveModel::ValidationError'
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
