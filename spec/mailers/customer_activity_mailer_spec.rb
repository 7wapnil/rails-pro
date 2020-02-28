describe CustomerActivityMailer do
  let(:customer) { create(:customer, email: 'igor@arcanebet.com') }

  it 'sends suspicipus login email' do
    email =
      described_class.with(customer: customer).suspicious_login(customer.email)
    expect(email.to.first).to eq(customer.email)
  end

  it 'sends reset password email' do
    email =
      described_class.with(customer: customer).reset_password_mail('FOOBAR')
    expect(email.to.first).to eq(customer.email)
  end
end
