describe GraphQL, '#app' do
  let(:query) do
    %({ app { status statuses live_connected pre_live_connected} })
  end
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
    expect(result['data']['app']['live_connected']).to eq(true)
    expect(result['data']['app']['pre_live_connected']).to eq(true)
  end

  it 'returns available statuses' do
    expect(result['data']['app']['statuses'])
      .to match_array(%w[inactive active])
  end
end
