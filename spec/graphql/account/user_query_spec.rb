describe GraphQL, '#user' do
  let(:request) do
    OpenStruct.new(remote_ip: Faker::Internet.ip_v4_address)
  end
  let(:customer) { create(:customer) }
  let(:context) { { request: request, current_customer: customer } }
  let(:variables) { {} }
  let(:result) do
    ArcanebetSchema.execute(query,
                            context: context,
                            variables: variables)
  end

  context 'basic fields' do
    let(:query) do
      %(query {
      user {
        id
        email
        username
        verified
        regular
        available_withdraw_methods
      }
    })
    end

    it 'returns user data on query' do
      expect(result['data']['user']).not_to be_nil
    end

    it 'returns user id' do
      expect(result['data']['user']['id']).to eq(customer.id.to_s)
    end

    it 'returns user verified status' do
      expect(result['data']['user']['verified']).to eq(false)
    end

    it 'returns user regularity' do
      expect(result['data']['user']['regular']).to eq(true)
    end

    it 'returns user available withdraw methods list' do
      expect(result['data']['user']['available_withdraw_methods']).to eq([])
    end
  end
end
