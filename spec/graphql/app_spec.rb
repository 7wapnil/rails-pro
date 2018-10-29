describe 'GraphQL#app' do
  let(:query) { %({ app { status } }) }
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  it 'returns app state' do
    expect(result['data']).not_to be_nil
    expect(result['data']['app']['status']).to eq('active')
  end
end
