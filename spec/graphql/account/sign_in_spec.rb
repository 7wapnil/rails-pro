describe 'GraphQL#SignIn' do
  let(:context) { {} }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:query) do
    %(mutation($input: AuthInput!) {
          signIn(input: $input) {
            user { id }
            token
          }
        })
  end

  context 'wrong input' do
    let(:variables) do
      { input: {} }
    end

    it 'should return argument error' do
      expect(result['errors'][0]['message'])
        .to eq('Variable input of type AuthInput! was provided invalid value')
    end
  end

  context 'non-existing user' do
    let(:variables) do
      { input: {
        username: 'unknown',
        password: '12345'
      } }
    end

    it 'should return wrong credentials error' do
      expect(result['errors'][0]['message'])
        .to eq('Wrong email or password')
    end
  end

  context 'existing user wrong password' do
    let!(:user) do
      create(:customer, username: 'testuser', password: 'strongpass')
    end
    let(:variables) do
      { input: {
        username: 'testuser',
        password: '12345'
      } }
    end

    it 'should return wrong credentials' do
      expect(result['errors'][0]['message'])
        .to eq('Wrong email or password')
    end
  end

  context 'existing user' do
    let!(:user) do
      create(:customer, username: 'testuser', password: 'strongpass')
    end
    let(:variables) do
      { input: {
        username: 'testuser',
        password: 'strongpass'
      } }
    end

    it 'should successfully sign in' do
      expect(result['data']['signIn']['token']).not_to be_nil
      expect(result['data']['signIn']['user']).not_to be_nil
    end
  end
end
