describe GraphQL, '#providers' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  before do
    create_list(:producer, 2)
  end

  context 'basic query' do
    let(:query) { %({ providers { id code state } }) }

    it 'returns list of providers' do
      expect(result['data']['providers'].count).to eq(2)
    end
  end
end
