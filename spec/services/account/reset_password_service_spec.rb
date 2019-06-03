describe Account::ResetPasswordService do
  subject { described_class.new(token, password, confirmation) }

  let(:token) { valid_token }
  let(:valid_token) { 'j_b8WrhPTZ3mqFsRgfEw' }
  let(:sent_at) { Time.now.utc }
  let(:password) { 'the-password' }
  let(:confirmation) { password }

  # rubocop:disable Metrics/LineLength
  let!(:customer) do
    create(
      :customer,
      reset_password_token: '1efe2f9f0ff5f7474a3a3143cb43b1d3e8dc6025abda9bcb0651e17208f99c02',
      reset_password_sent_at: sent_at
    )
  end
  # rubocop:enable Metrics/LineLength

  context 'with valid token and matching passwords' do
    it 'calls reset_password on customer' do
      allow_any_instance_of(Customer).to receive(:reset_password)
      expect_any_instance_of(Customer).to receive(:reset_password)

      subject.call
    end
  end

  context 'with missing token' do
    let(:token) { nil }

    it 'raises error' do
      expect { subject.call }.to(
        raise_error(
          GraphQL::ExecutionError,
          'Empty reset token'
        )
      )
    end
  end

  context 'with invalid token' do
    let(:token) { 'the-missing-token' }

    it 'raises error' do
      expect { subject.call }.to(
        raise_error(
          GraphQL::ExecutionError,
          'No user found for password reset token'
        )
      )
    end
  end

  context 'with expired token' do
    let(:sent_at) { 10.years.ago }

    it 'raises error' do
      expect { subject.call }.to(
        raise_error(
          GraphQL::ExecutionError,
          'Reset password token expired'
        )
      )
    end
  end

  context 'with password mismatch' do
    let(:confirmation) { 'something-else' }

    it 'raises error' do
      expect { subject.call }.to(
        raise_error(
          GraphQL::ExecutionError,
          'Confirmation does not match password'
        )
      )
    end
  end
end
