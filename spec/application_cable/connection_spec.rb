describe ApplicationCable::Connection, type: :channel do
  let(:customer) { create(:customer) }
  let(:token) do
    JwtService.encode(
      id:       customer.id,
      username: customer.username,
      email:    customer.email,
      exp:      30.days.from_now.to_i
    )
  end

  it 'authenticates customer by token param' do
    connect "/cable?token=#{token}"
    expect(connection.customer).not_to be_nil
  end

  it 'authenticates right customer' do
    connect "/cable?token=#{token}"
    expect(connection.customer.id).to eq(customer.id)
  end

  it 'not authenticates if token not received' do
    connect '/cable'
    expect(connection.customer).to be_nil
  end

  it 'not authenticates if token unknown' do
    connect '/cable?token=unknown-token'
    expect(connection.customer).to be_nil
  end
end
