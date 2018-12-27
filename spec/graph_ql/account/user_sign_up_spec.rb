describe GraphQL, '#sign_up' do
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

  let(:query) do
    %(query {
      user {
        id
        email
        username
        verified
        regular
      }
    })
  end

  it 'returns user data on query' do
    expect(result['data']['user']).not_to be_nil
    expect(result['data']['user']['id']).to eq(customer.id.to_s)
    expect(result['data']['user']['verified']).to eq(false)
    expect(result['data']['user']['regular']).to eq(true)
  end
end
