describe 'GraphQL#app' do
  let(:query) { %({ app { status statuses flags} }) }
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
      .to match_array(%w[inactive active])
  end

  context 'with one valid flag added ' do
    before do
      ApplicationState.instance.instance_variable_set(:@flags, [])
      ApplicationState.instance.enable_flag(:prematch_odds_feed_offline)
    end

    it 'returns available flags' do
      expect(result['data']['app']['flags'])
        .to match_array(['prematch_odds_feed_offline'])
    end
  end
end
