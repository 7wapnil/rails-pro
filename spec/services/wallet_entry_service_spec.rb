describe WalletEntry::Service do
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

      expect(request.failed?).to be true
      expect(request.result['exception_class'])
        .to eq 'ActiveRecord::RecordInvalid'
    end

    it 'updates entry request on success' do
      expect_any_instance_of(WalletEntry::Service)
        .not_to receive(:handle_failure)

      WalletEntry::Service.call(request)

      expect(request.succeeded?).to be true
      expect(request.result).not_to be_present
    end
  end

  context 'existing wallet' do
    let!(:wallet) { create(:wallet, amount: 50) }

    let!(:balance) { create(:balance, amount: 50, wallet: wallet) }

    let(:request) do
      create(:entry_request,
             customer: wallet.customer,
             currency: wallet.currency)
    end

    context 'increment' do
      before do
        request.kind = EntryKinds::KINDS[:deposit]
        request.amount = 10
      end

      it 'increments wallet amount' do
        described_class.call(request)
        wallet.reload

        expect(wallet.amount).to eq 60
      end

      it 'increments balance amount' do
        described_class.call(request)
        balance.reload

        expect(balance.amount).to eq 60
      end
    end

    context 'decrement' do
      let(:rule) do
        create(:entry_currency_rule, min_amount: -500, max_amount: 0)
      end

      before do
        allow(EntryCurrencyRule).to receive(:find_by!) { rule }
        request.kind = EntryKinds::KINDS[:withdraw]
      end

      it 'decrements wallet amount' do
        request.amount = -10

        described_class.call(request)
        wallet.reload

        expect(wallet.amount).to eq 40
      end

      it 'decrements balance amount' do
        request.amount = -10

        described_class.call(request)
        balance.reload

        expect(balance.amount).to eq 40
      end

      it 'fails to update wallet amount to negative' do
        error_message = I18n.t('errors.messages.with_instance.not_negative',
                               instance: I18n.t('entities.wallet'))

        request.amount = -60

        described_class.call(request)
        wallet.reload

        expect(wallet.amount).to eq 50
        expect(request.failed?).to be true
        expect(request.result_message).to include error_message
      end

      it 'fails to update balance amount to negative' do
        error_message = I18n.t('errors.messages.with_instance.not_negative',
                               instance: I18n.t('entities.balance'))

        balance.update_attributes!(amount: 30)
        request.amount = -40

        described_class.call(request)
        balance.reload

        expect(balance.amount).to eq 30
        expect(request.failed?).to be true
        expect(request.result_message).to include error_message
      end
    end
  end
end
