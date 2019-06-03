describe Devise::ResetPasswordToken::CustomerLoader do
  let(:correct_token) { 'j_b8WrhPTZ3mqFsRgfEw' }

  # rubocop:disable Metrics/LineLength
  let!(:customer) do
    create(
      :customer,
      email_verified: true,
      reset_password_token: '1efe2f9f0ff5f7474a3a3143cb43b1d3e8dc6025abda9bcb0651e17208f99c02'
    )
  end
  # rubocop:enable Metrics/LineLength

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
