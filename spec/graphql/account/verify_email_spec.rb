describe GraphQL, '#verify_email' do
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: {},
                            variables: variables)
  end

  let(:query) do
    %(mutation($token: String!) {
        verifyEmail(token: $token) {
          success
          userId
        }
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

  context 'email verification' do
    let(:token) { 'generated-token' }
    let(:variables) do
      { token: token }
    end
    let(:customer) do
      create(:customer, email_verification_token: token, email_verified: false)
    end

    it 'returns true on successful activation' do
      customer
      expect(result['data']['verifyEmail']['success']).to be_truthy
    end

    it 'renders a userId' do
      customer
      expect(result['data']['verifyEmail']['userId']).to eq(customer.id.to_s)
    end
  end
end
