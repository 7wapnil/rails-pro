describe DataAdjustments::RemoveCustomerBalance do
  before { create(:currency, :primary) }

  # rubocop:disable RSpec/MultipleExpectations

  let(:customer) { create(:customer) }

  it 'removes balance from a single non-empty wallet' do
    fiat_wallet = create(:wallet, :fiat, :empty, customer: customer)
    crypto_wallet = create(:wallet, :crypto, customer: customer)

    expect(WalletEntry::AuthorizationService)
      .to receive(:call)
      .once
      .and_call_original

    described_class.call(customer.id)

    expect(fiat_wallet.reload)
      .to have_attributes(amount: 0, real_money_balance: 0, bonus_balance: 0)
    expect(crypto_wallet.reload)
      .to have_attributes(amount: 0, real_money_balance: 0, bonus_balance: 0)
  end

  it 'removes balance from multiple non-empty wallets' do
    fiat_wallet = create(:wallet, :fiat, customer: customer)
    crypto_wallet = create(:wallet, :crypto, customer: customer)

    expect(WalletEntry::AuthorizationService)
      .to receive(:call)
      .twice
      .and_call_original

    described_class.call(customer.id)

    expect(fiat_wallet.reload)
      .to have_attributes(amount: 0, real_money_balance: 0, bonus_balance: 0)
    expect(crypto_wallet.reload)
      .to have_attributes(amount: 0, real_money_balance: 0, bonus_balance: 0)
  end

  it 'skips empty wallet' do
    create(:wallet, :empty, customer: customer)

    expect(WalletEntry::AuthorizationService).not_to receive(:call)

    described_class.call(customer.id)
  end

  it 'skips wallet with negative balance' do
    wallet = create(
      :wallet,
      amount: -100,
      real_money_balance: -100,
      bonus_balance: 0,
      customer: customer
    )

    expect(WalletEntry::AuthorizationService).not_to receive(:call)

    described_class.call(customer.id)

    expect(wallet.reload.amount).to eq(-100)
    expect(wallet.reload.real_money_balance).to eq(-100)
    expect(wallet.reload.bonus_balance).to eq(0)
  end
  # rubocop:enable RSpec/MultipleExpectations
end
