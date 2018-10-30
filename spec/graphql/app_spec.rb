describe 'GraphQL#app' do
  let(:query) { %({ app { status statuses} }) }
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query, context: context, variables: variables)
  end

  it 'returns app state' do
    expect(result['data']).not_to be_nil
  end

  it 'returns default status' do
    expect(result['data']['app']['status']).to eq('active')
  end

  it 'returns available statuses' do
    expect(result['data']['app']['statuses'])
      .to match_array(["inactive", "active"])
  end
end
