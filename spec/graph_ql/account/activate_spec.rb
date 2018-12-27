describe GraphQL, '#activate' do
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: {},
                            variables: variables)
  end

  let(:query) do
    %(mutation($token: String!) {
        activate(token: $token)
      })
  end

  context 'wrong token' do
    let(:variables) do
      { token: 'not-existing' }
    end

    it 'returns customer not found error' do
      expect(result['errors'][0]['message']).to eq('Couldn\'t find Customer')
    end
  end

  context 'activated token' do
    let(:token) { 'generated-token' }
    let(:variables) do
      { token: token }
    end

    before do
      create(:customer, activation_token: token, activated: true)
    end

    it 'returns customer already activated error' do
      expect(result['errors'][0]['message']).to eq('Customer already activated')
    end
  end

  context 'activation' do
    let(:token) { 'generated-token' }
    let(:variables) do
      { token: token }
    end

    before do
      create(:customer, activation_token: token, activated: false)
    end

    it 'returns true on successful activation' do
      expect(result['data']['activate']).to be_truthy
    end
  end
end
