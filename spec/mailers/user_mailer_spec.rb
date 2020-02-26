describe UserMailer do
  let(:customer) { create(:customer, email: 'igor@arcanebet.com') }
  let(:admin) { create(:user) }
  let(:app_host) { Faker::Internet.domain_name }

  before do
    allow(ENV).to receive(:[])
      .with('ADMIN_NOTIFY_MAIL')
      .and_return(admin.email)

    allow(ENV)
      .to receive(:[])
      .with('APP_HOST')
      .and_return(app_host)
  end

  it 'sends negative balance bet placement error' do
    email =
      described_class.with(customer: customer).negative_balance_bet_placement
    expect(email.to.first).to eq(admin.email)
  end
end
