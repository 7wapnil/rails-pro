describe Devise::ResetPasswordToken::CustomerLoader do
  let(:devise_tokens) do
    Devise.token_generator.generate(Customer, :reset_password_token)
  end

  let(:correct_token) { devise_tokens.first }

  let!(:customer) do
    create(
      :customer,
      email_verified: true,
      reset_password_token: devise_tokens.last
    )
  end

  it 'returns correct customer with correct token' do
    expect(described_class.call(correct_token)).to eq customer
  end

  it 'returns empty customer with incorrect token' do
    customer = described_class.call('FOOBAR')
    expect(customer.persisted?).to be false
  end

  it 'raises ArgumentError without a token' do
    expect { described_class.call }.to raise_error(ArgumentError)
  end
end
