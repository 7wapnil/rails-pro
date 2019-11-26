# frozen_string_literal: true

describe GraphQL, '#signUp' do
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
    %(mutation($input: RegisterInput!, $userData: UserDataInput) {
        signUp(input: $input, userData: $userData) {
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
        dateOfBirth: '01-01-2018',
        password: '123456',
        country: 'Canada',
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
      expect(paths)
        .to match_array(%i[agreedWithPrivacy email dateOfBirth])
    end
  end

  context 'successful sing up' do
    let(:input) do
      {
        username: 'test',
        email: 'test@email.com',
        dateOfBirth: '01-01-1998',
        password: '123456',
        country: 'Canada',
        agreedWithPromotional: true,
        agreedWithPrivacy: true,
        bTag: 'AFFILIATE_ID',
        currency: 'EUR'
      }
    end

    context 'without fe tracking' do
      let(:variables) do
        { input: input }
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
        expect(Customer.find_by(email: 'test@email.com').wallets)
          .not_to be_empty
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
                              b_tag: 'AFFILIATE_ID')
      end

      it 'creates no customer data record' do
        expect { result }.not_to change(CustomerData, :count)
      end
    end

    context 'with fe tracking' do
      let(:variables) do
        { input: input, userData: customer_data }
      end
      let(:customer_data) do
        {
          trafficTypeLast: Faker::Lorem.word,
          utmSourceLast: Faker::Lorem.word,
          utmMediumLast: Faker::Lorem.word,
          utmCampaignLast: Faker::Lorem.word,
          utmContentLast: Faker::Lorem.word,
          utmTermLast: Faker::Lorem.word,
          visitcountLast: Faker::Lorem.word,
          browserLast: Faker::Lorem.word,
          deviceTypeLast: Faker::Lorem.word,
          devicePlatformLast: Faker::Lorem.word,
          registrationUrlLast: Faker::Lorem.word,
          timestampVisitLast: Faker::Lorem.word,
          entrancePageLast: Faker::Lorem.word,
          referrerLast: Faker::Lorem.word,
          currentBtag: Faker::Lorem.word,
          trafficTypeFirst: Faker::Lorem.word,
          utmSourceFirst: Faker::Lorem.word,
          utmMediumFirst: Faker::Lorem.word,
          utmCampaignFirst: Faker::Lorem.word,
          utmTermFirst: Faker::Lorem.word,
          timestampVisitFirst: Faker::Lorem.word,
          entrancePageFirst: Faker::Lorem.word,
          referrerFirst: Faker::Lorem.word,
          gaClientID: Faker::Lorem.word
        }
      end
      let(:customer) { Customer.find_by(email: input[:email]) }
      let(:created_customer_data) { CustomerData.find_by(customer: customer) }

      it 'creates a customer data record with passed values' do
        result
        expect(created_customer_data).to have_attributes(
          customer_data.transform_keys! do |key|
            key.to_s.underscore.to_sym
          end
        )
      end
    end
  end

  context 'not agreing with ToS' do
    let(:variables) do
      { input: {
        username: 'test',
        email: 'test@email.com',
        dateOfBirth: '01-01-1998',
        password: '123456',
        country: 'Canada',
        agreedWithPromotional: true,
        agreedWithPrivacy: false,
        bTag: 'AFFILIATE_ID',
        currency: 'EUR'
      } }
    end

    it 'returns a validation error' do
      expect(result['errors'][0]['message']).not_to be_empty
    end

    it 'does not create a customer' do
      expect(Customer.find_by(email: variables[:input][:email])).to be_nil
    end
  end
end
