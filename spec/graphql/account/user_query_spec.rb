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
        availableWithdrawalMethods
      }
    })
    end

    it 'returns user data on query' do
      expect(result['data']['user']).not_to be_nil
    end

    it 'returns requested attributes' do
      expect(result['data']['user'])
        .to include('id' => customer.id.to_s,
                    'verified' => true,
                    'regular' => true,
                    'availableWithdrawalMethods' => [])
    end
  end
end
