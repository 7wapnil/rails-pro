describe GraphQL, '#wallets' do
  let(:auth_customer) { create(:customer) }
  let(:context) { { current_customer: auth_customer } }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe 'query' do
    let(:query) { %({ wallets { id amount currency { code name } } }) }

    it 'returns list of auth customer wallets' do
      5.times do |n|
        currency = create(:currency, code: "XX#{n}")
        create(:wallet, customer: auth_customer, currency: currency)
      end
      create_list(:wallet, 2)
      expect(result['data']['wallets'].count).to eq(5)
    end

    it 'returns wallet currency fields' do
      wallet = create(:wallet, customer: auth_customer)
      result_wallet = result['data']['wallets'].first

      expect(result_wallet['id']).to eq(wallet.id.to_s)
      expect(result_wallet['currency']['code']).to eq(wallet.currency.code)
      expect(result_wallet['currency']['name']).to eq(wallet.currency.name)
    end

    it 'returns default wallet when customer has no any' do
      expect(result['data']['wallets'].count).to eq(1)
      result_wallet = result['data']['wallets'].first
      default_currency = Currency.build_default

      expect(result_wallet['amount']).to eq(0)
      expect(result_wallet['currency']['code']).to eq(default_currency.code)
    end
  end
end
