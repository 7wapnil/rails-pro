describe ArcanebetMailer do
  it 'must have default from address' do
    expect(subject.default_params[:from]).to eq('noreply@arcanebet.com')
  end

  it 'must have default subject' do
    expect(subject.default_params[:subject]).to eq('ArcaneBet')
  end

  context 'emails' do
    let(:customer) { create(:customer, email: 'igor@arcanebet.com') }

    it 'sends account activation email' do
      email = described_class.with(customer: customer).account_activation_mail
      expect(email.to.first).to eq(customer.email)
    end
  end
end
