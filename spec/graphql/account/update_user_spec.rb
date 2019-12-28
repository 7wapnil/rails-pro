# frozen_string_literal: true

describe GraphQL, '#updateUser' do
  let!(:auth_customer) { create(:customer, :with_address) }
  let(:request) do
    OpenStruct.new(remote_ip: Faker::Internet.ip_v4_address)
  end
  let(:context) { { current_customer: auth_customer, request: request } }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  let(:query) do
    %(mutation ($input: UpdateUserInput!) {
      updateUser(input: $input) {
        firstName
        lastName
        phone
        addressState
        addressCity
        addressZipCode
        addressStreetAddress
        needMoreInfo
      }
    })
  end

  context 'wrong input' do
    let(:variables) do
      { input: {} }
    end

    it 'returns argument error' do
      msg = 'Variable input of type '\
            'UpdateUserInput! was provided invalid value'
      expect(result['errors'][0]['message']).to eq(msg)
    end
  end

  context 'validation errors' do
    let(:variables) do
      {
        input: {
          firstName: 'qweqw',
          lastName: '',
          state: 'London',
          city: '',
          zipCode: '79000',
          streetAddress: 'Baker st',
          phone: '+12065550100'
        }
      }
    end

    it 'returns several validation errors' do
      expect(result['errors'].size > 1).to be_truthy
    end

    it 'returns collection of validation errors' do
      paths = result['errors'].map { |err| err['path'][0].to_sym }
      expect(paths).to match_array(%i[city lastName])
    end
  end

  context 'no errors' do
    let(:variables) do
      {
        input: {
          firstName: 'qweqw',
          lastName: 'test1',
          state: 'London',
          city: 'London',
          zipCode: '79000',
          streetAddress: 'Baker st',
          phone: '+12065550100'
        }
      }
    end

    it 'does not return errors' do
      expect(result['errors']).to be_nil
    end

    it 'returns updated customer data' do
      expect(OpenStruct.new(result['data']['updateUser'])).to have_attributes(
        firstName: 'qweqw',
        lastName: 'test1',
        addressState: 'London',
        addressCity: 'London',
        addressZipCode: '79000',
        addressStreetAddress: 'Baker st',
        phone: '+12065550100'
      )
    end

    it 'returns that customer info is totally fulfilled' do
      expect(result['data']['updateUser']['needMoreInfo']).to be_falsey
    end

    context 'when there is no enough customer info fulfilled' do
      before { auth_customer.address.update(country: nil) }

      it 'returns that customer has not filled all the needed info' do
        expect(result['data']['updateUser']['needMoreInfo']).to be_truthy
      end
    end
  end
end
