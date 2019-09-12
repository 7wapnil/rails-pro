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
    let(:currencies) do
      (1..currencies_in_system).map do |n|
        create(:currency, code: "XX#{n}")
      end
    end

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
  end
end
