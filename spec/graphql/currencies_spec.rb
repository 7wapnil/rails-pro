describe GraphQL, '#currencies' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  describe 'query' do
    let(:query) { %({ currencies { id name code primary } }) }

    let(:currencies_in_system) { 2 }
    let(:currencies) do
      Array.new(currencies_in_system) { |_| build_stubbed(:currency) }
    end

    let(:expected_result_array) do
      currencies.map do |currency|
        {
          code: currency.code.to_s,
          id: currency.id.to_s,
          name: currency.name.to_s,
          primary: currency.primary
        }.stringify_keys!
      end
    end

    before do
      allow(Currency).to receive(:all) { currencies }
    end

    it 'returns correct content of existing currencies' do
      expect(result['data']['currencies']).to match_array(expected_result_array)
    end
  end
end
