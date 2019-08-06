describe Customers::ImpersonationService do
  let(:user) { create(:user) }
  let(:customer) { create(:customer) }
  let(:token) { 'token' }
  let(:payload) do
    {
      id: customer.id,
      impersonated_by: user.id,
      email: customer.email,
      username: customer.username,
      wallets: []
    }
  end

  it 'returns link to frontend app to login as impersonated customer' do
    allow(JwtService).to receive(:encode).with(payload).and_return(token)
    customer_params = payload.slice(:email, :username, :id, :wallets)
    params = "#{token}?customer=#{customer_params.to_json}"
    impersonation_link = "#{ENV['FRONTEND_URL']}/impersonate/#{params}"
    link = described_class.call(user, customer)

    expect(impersonation_link).to eq(link)
  end

  it 'encodes customer payload' do
    allow(JwtService).to receive(:encode)
    described_class.call(user, customer)

    expect(JwtService).to have_received(:encode).with(payload)
  end
end
