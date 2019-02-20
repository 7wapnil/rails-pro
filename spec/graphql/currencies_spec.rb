describe GraphQL, '#currencies' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe '#resolve' do
    let(:query) { %({ currencies { id name code primary kind } }) }

    let(:currencies_in_system) { 2 }
    let(:currencies) { create_list(:currency, currencies_in_system) }

    let!(:expected_result_array) do
      currencies.map do |currency|
        {
          code: currency.code,
          id: currency.id.to_s,
          name: currency.name,
          primary: currency.primary,
          kind: currency.kind
        }.stringify_keys!
      end
    end

    it 'returns correct content of existing currencies' do
      expect(result['data']['currencies']).to match_array(expected_result_array)
    end

    context 'when multiple calls made' do
      before do
        allow(Currency).to receive(:all) { currencies }
        Rails.cache.delete(Currencies::CurrencyQuery::CACHE_KEY)
        2.times { result }
      end

      it 'caches responses' do
        expect(Currency).to have_received(:all).once
      end
    end

    context 'when multiple calls made with data changed on the go' do
      before do
        allow(Currency).to receive(:all) { currencies }
        Rails.cache.delete(Currencies::CurrencyQuery::CACHE_KEY)
        result
        Currency.first.update(code: 'NEW')
        result
      end

      it 'caches responses' do
        expect(Currency).to have_received(:all).twice
      end
    end
  end
end
