describe Withdrawals::WithdrawalRequestBuilder do
  let(:created_entry_request) { described_class.call(wallet, withdraw_amount) }
  let(:wallet) { create(:wallet) }
  let(:withdraw_amount) { 100 }

  it 'returns created entry request' do
    expect(created_entry_request).to be_instance_of(EntryRequest)
  end

  it 'creates entry request with correct kind' do
    expect(created_entry_request).to be_withdraw
  end

  it 'creates entry request with correct amount' do
    expect(created_entry_request.amount).to eq(-withdraw_amount)
  end

  it 'creates entry request with correct currency' do
    expect(created_entry_request.currency).to eq(wallet.currency)
  end

  it 'creates entry request with correct customer' do
    expect(created_entry_request.customer).to eq(wallet.customer)
  end

end
