# frozen_string_literal: true

describe Customers::ImpersonationService do
  subject { described_class.call(user, customer) }

  let(:user) { create(:user) }
  let(:customer) { create(:customer) }
  let(:token) { Faker::WorldOfWarcraft.hero }
  let(:frontend_url) { Faker::Internet.url }
  let(:payload) do
    {
      id: customer.id,
      username: customer.username,
      email: customer.email,
      impersonated_by: user.id,
      exp: 30.days.from_now.to_i
    }
  end

  before do
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with('FRONTEND_URL').and_return(frontend_url)
    allow(ENV).to receive(:fetch).with('TOKEN_EXPIRATION', 30).and_return(30)
    allow(JwtService).to receive(:encode).with(payload).and_return(token)
  end

  it 'logs impersonation attempt' do
    expect(user)
      .to receive(:log_event)
      .with(:impersonate_customer, {}, customer)

    subject
  end

  it 'returns link to frontend app to login as impersonated customer' do
    expect(subject).to eq("#{ENV['FRONTEND_URL']}/impersonate/#{token}")
  end
end
