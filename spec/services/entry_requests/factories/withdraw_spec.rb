describe EntryRequests::Factories::Withdraw do
  subject(:service) do
    described_class.new(wallet: wallet,
                        amount: withdraw_amount,
                        mode: EntryRequest::CASHIER)
  end

  let(:withdraw_amount) { 50 }
  let(:wallet) { create(:wallet) }

  context 'when success' do
    let(:created_request) { service.call }
    let(:expected_attrs) do
      {
        amount: -withdraw_amount,
        currency_id: wallet.currency_id,
        customer_id: wallet.customer_id,
        mode: EntryRequest::CASHIER
      }
    end

    it 'returns created entry request' do
      expect(created_request).to be_instance_of(EntryRequest)
    end

    it 'assigns correct entry request attributes' do
      assigned_attrs = created_request
                       .slice(:amount, :currency_id, :customer_id, :mode)
                       .symbolize_keys

      expect(assigned_attrs).to eq(expected_attrs)
    end

    it 'build balance entry requests' do
      entry_request = create(:entry_request)
      allow(EntryRequest).to receive(:create!).and_return(entry_request)

      expect(BalanceRequestBuilders::Withdraw)
        .to receive(:call)
        .with(entry_request, real_money: -withdraw_amount)

      service.call
    end
  end
end
