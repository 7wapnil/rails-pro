describe 'GraphQL#SignIn' do
  let(:request) do
    OpenStruct.new(remote_ip: Faker::Internet.ip_v4_address)
  end
  let(:context) { { request: request } }
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

    it 'returns argument error' do
      expect(result['errors'][0]['message'])
        .to eq('Variable input of type AuthInput! was provided invalid value')
    end
  end

  context 'non-existing user' do
    let(:variables) do
      { input: {
        login: 'unknown',
        password: '12345'
      } }
    end

    it 'returns wrong credentials error' do
      expect(result['errors'][0]['message'])
        .to eq('Wrong username, email or password')
    end
  end

  context 'existing user wrong password' do
    let!(:user) do
      create(:customer, username: 'testuser', password: 'strongpass')
    end
    let(:variables) do
      { input: {
        login: 'testuser',
        password: '12345'
      } }
    end

    it 'returns wrong credentials' do
      expect(result['errors'][0]['message'])
        .to eq('Wrong username, email or password')
    end
  end

  context 'existing user' do
    let!(:user) do
      create(:customer, username: 'testuser', password: 'strongpass')
    end
    let(:variables) do
      { input: {
        login: 'testuser',
        password: 'strongpass'
      } }
    end

    it 'signs in successfully' do
      expect(result['data']['signIn']['token']).not_to be_nil
      expect(result['data']['signIn']['user']).not_to be_nil
    end

    it 'logs audit event' do
      allow(Audit::Service).to receive(:call)
      expect(result['data']['signIn']['token']).not_to be_nil
      expect(Audit::Service).to have_received(:call)
    end
  end

  context 'existing user with case-insensitive username' do
    let!(:user) do
      create(:customer, username: 'testuser', password: 'strongpass')
    end
    let(:variables) do
      { input: {
        login: 'TESTuSeR',
        password: 'strongpass'
      } }
    end

    it 'signs in successfully' do
      expect(result['data']['signIn']['token']).not_to be_nil
      expect(result['data']['signIn']['user']).not_to be_nil
    end
  end
end
