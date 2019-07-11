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

  before { create(:currency, code: 'EUR') }

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
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '01-01-2018',
        password: '123456',
        passwordConfirmation: '123456',
        gender: Customer::FEMALE,
        country: 'Canada',
        city: 'Toronto',
        state: 'State',
        zipCode: '123',
        streetAddress: 'Street Addr',
        phone: '1232132132',
        agreedWithPromotional: true,
        agreedWithPrivacy: false,
        currency: 'EUR'
      } }
    end

    it 'returns several validation errors' do
      expect(result['errors'].size > 1).to be_truthy
    end

    it 'returns collection of validation errors' do
      paths = result['errors'].map { |err| err['path'][0].to_sym }
      expect(paths).to match_array(%i[signUp agreedWithPrivacy email phone])
    end
  end

  context 'successful sing up' do
    let(:variables) do
      { input: {
        username: 'test',
        email: 'test@email.com',
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '01-01-1998',
        password: '123456',
        passwordConfirmation: '123456',
        gender: Customer::FEMALE,
        country: 'Canada',
        city: 'Toronto',
        state: 'State',
        zipCode: '123',
        streetAddress: 'Street Addr',
        phone: '37258383943',
        agreedWithPromotional: true,
        agreedWithPrivacy: true,
        bTag: 'AFFILIATE_ID',
        currency: 'EUR'
      } }
    end

    it 'returns user and token' do
      expect(result['errors']).to be_nil
      expect(result['data']['signUp']['user']).not_to be_nil
      expect(result['data']['signUp']['token']).not_to be_nil
    end

    it 'creates new customer record' do
      result
      expect(Customer.find_by(email: 'test@email.com')).not_to be_nil
    end

    it 'creates customer related wallet' do
      result
      expect(Customer.find_by(email: 'test@email.com').wallets).not_to be_empty
    end

    it 'logs audit event on sign up' do
      allow(Audit::Service).to receive(:call)
      expect(result['errors']).to be_nil
      expect(Audit::Service).to have_received(:call)
    end

    it 'stores received data for custom' do
      result
      expect(Customer.find_by(email: 'test@email.com'))
        .to have_attributes(username: 'test',
                            first_name: 'Test',
                            last_name: 'User',
                            b_tag: 'AFFILIATE_ID')
    end
  end

  context 'not agreing with ToS' do
    let(:variables) do
      { input: {
        username: 'test',
        email: 'test@email.com',
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '01-01-1998',
        password: '123456',
        passwordConfirmation: '123456',
        gender: Customer::FEMALE,
        country: 'Canada',
        city: 'Toronto',
        state: 'State',
        zipCode: '123',
        streetAddress: 'Street Addr',
        phone: '37258383943',
        agreedWithPromotional: true,
        agreedWithPrivacy: false,
        bTag: 'AFFILIATE_ID',
        currency: 'EUR'
      } }
    end

    it 'returns a validation error' do
      expect(result['errors'][0]['message']).not_to be_blank
    end

    it 'does not create a customer' do
      expect(Customer.find_by(email: variables[:input][:email])).to be_nil
    end
  end
end
