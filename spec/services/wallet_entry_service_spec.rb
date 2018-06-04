describe 'WalletService', type: :service do
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

  it 'should be initialized with request object' do
    WalletEntryService.call(request.id)
  end
end
