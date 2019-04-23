describe GraphQL, '#verify_email' do
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: {},
                            variables: variables)
  end

  let(:query) do
    %(mutation($token: String!) {
        verifyEmail(token: $token)
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

  context 'verified token' do
    let(:token) { 'generated-token' }
    let(:variables) do
      { token: token }
    end

    before do
      create(:customer, email_verification_token: token, email_verified: true)
    end

    it 'returns customer already activated error' do
      expect(result['errors'][0]['message']).to eq('Email already verified')
    end
  end

  context 'emal verification' do
    let(:token) { 'generated-token' }
    let(:variables) do
      { token: token }
    end

    before do
      create(:customer, email_verification_token: token, email_verified: false)
    end

    it 'returns true on successful activation' do
      expect(result['data']['verifyEmail']).to be_truthy
    end
  end
end
