describe GraphQL do
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
    %(mutation($input: RegisterInput!) {
        signUp(input: $input) {
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
      msg = 'Variable input of type RegisterInput! was provided invalid value'
      expect(result['errors'][0]['message']).to eq(msg)
    end
  end

  context 'validation errors' do
    let(:variables) do
      { input: {
        username: 'test',
        email: 'wrongemail',
        first_name: 'Test',
        last_name: 'User',
        date_of_birth: '01-01-2018',
        password: '123456',
        password_confirmation: '123456',
        gender: Customer::FEMALE,
        country: 'Canada',
        city: 'Toronto',
        state: 'State',
        zip_code: '123',
        street_address: 'Street Addr',
        phone: '1232132132',
        agreed_with_promotional: true
      } }
    end

    it 'returns collection of validation errors' do
      expect(result['errors'][0]['path']).to eq(:email)
      expect(result['errors'][0]['message']).to eq('Email is invalid')
    end
  end

  context 'successful sing up' do
    let(:variables) do
      { input: {
        username: 'test',
        email: 'test@email.com',
        first_name: 'Test',
        last_name: 'User',
        date_of_birth: '01-01-1998',
        password: '123456',
        password_confirmation: '123456',
        gender: Customer::FEMALE,
        country: 'Canada',
        city: 'Toronto',
        state: 'State',
        zip_code: '123',
        street_address: 'Street Addr',
        phone: '37258383943',
        agreed_with_promotional: true
      } }
    end

    it 'returns user and token' do
      expect(result['errors']).to be_nil
      expect(result['data']['signUp']['user']).not_to be_nil
      expect(result['data']['signUp']['token']).not_to be_nil
    end

    it 'logs audit event on sign up' do
      allow(Audit::Service).to receive(:call)
      expect(result['errors']).to be_nil
      expect(Audit::Service).to have_received(:call)
    end
  end
end