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

    describe 'relies on cached data' do
      before do
        allow(Currency).to receive(:cached_all) { [create(:currency)] }
      end

      it 'returns cached source length of currencies' do
        expect(result['data']['currencies'].size).to eq 1
      end
    end
  end
end
