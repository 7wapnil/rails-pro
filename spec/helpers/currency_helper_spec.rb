describe CurrencyHelper, type: :helper do
  describe '#currencies_with_primary_for' do
    it 'returns only primary currency for customer without wallets' do
      customer = create(:customer)
      primary_currency = create(:currency, :primary)
      not_included_currency = create(:currency)

      expect(helper.currencies_with_primary_for(customer))
        .to eq([primary_currency])
      expect(helper.currencies_with_primary_for(customer))
        .not_to include(not_included_currency)
    end

    it 'returns customer currencies with primary' do
      customer = create(:customer)
      primary_currency = create(:currency, :primary)
      not_included_currency = create(:currency)
      wallet = create(:wallet, customer: customer)

      expect(helper.currencies_with_primary_for(customer))
        .to include(primary_currency, wallet.currency)
      expect(helper.currencies_with_primary_for(customer))
        .not_to include(not_included_currency)
    end

    it 'doesn\'t create new customer wallet' do
      customer = create(:customer)
      create(:currency, :primary)
      helper.currencies_with_primary_for(customer)
      expect(customer.wallets).to be_empty
    end
  end
end