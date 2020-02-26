describe CustomerAccountMailer do
  let(:customer) { create(:customer, email: 'igor@arcanebet.com') }

  it 'sends email verification email' do
    email =
      described_class.with(customer: customer).email_verification_mail
    expect(email.to.first).to eq(customer.email)
  end

  it 'sends account verification mail' do
    email =
      described_class.with(customer: customer).account_verification_mail
    expect(email.to.first).to eq(customer.email)
  end
end
