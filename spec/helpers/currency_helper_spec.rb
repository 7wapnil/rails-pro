describe CurrencyHelper, type: :helper do
  describe '#currencies_with_primary_for' do
    let(:customer) { create(:customer) }
    let!(:primary_currency) { create(:currency, :primary) }
    let!(:not_included_currency) { create(:currency) }

    it 'returns only primary currency for customer without wallets' do
      expect(helper.currencies_with_primary_for(customer))
        .to eq([primary_currency])
      expect(helper.currencies_with_primary_for(customer))
        .not_to include(not_included_currency)
    end

    it 'returns customer currencies with primary' do
      wallet = create(:wallet, customer: customer)

      expect(helper.currencies_with_primary_for(customer))
        .to include(primary_currency, wallet.currency)
      expect(helper.currencies_with_primary_for(customer))
        .not_to include(not_included_currency)
    end

    it 'doesn\'t create new customer wallet' do
      create(:currency, :primary)
      helper.currencies_with_primary_for(customer)
      expect(customer.wallets).to be_empty
    end
  end
end
