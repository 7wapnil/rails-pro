describe GraphQL, '#app' do
  let(:query) do
    %({
      app {
        live_connected
        pre_live_connected
        upcoming_events_duration
      }
    })
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
    expect(result['data']['app']['live_connected']).to eq(true)
    expect(result['data']['app']['pre_live_connected']).to eq(true)
    expect(result['data']['app']['upcoming_events_duration'])
      .to eq(::Event::UPCOMING_DURATION_IN_HOURS)
  end
end
