# frozen_string_literal: true

describe GraphQL, '#requestPasswordReset' do
  let!(:customer) { create(:customer) }
  let(:variables) { { email: customer.email, captcha: '' } }
  let(:raw_token) { SecureRandom.hex(7) }
  let(:reset_password_token) { SecureRandom.hex(7) }

  let(:result) do
    ArcanebetSchema.execute(query,
                            context: {},
                            variables: variables)
  end

  let(:query) do
    %(mutation($email: String!, $captcha: String!) {
        requestPasswordReset(email: $email, captcha: $captcha)
      })
  end

  let(:mailer) { double }

  include_context 'frozen_time' do
    let(:frozen_time) { Time.zone.now }
  end

  before do
    allow(Devise.token_generator)
      .to receive(:generate)
      .with(Customer, :reset_password_token)
      .and_return([raw_token, reset_password_token])

    mailer_chain_mock = double
    allow(ArcanebetMailer)
      .to receive(:with)
      .with(customer: customer)
      .and_return(mailer_chain_mock)

    allow(mailer_chain_mock)
      .to receive(:reset_password_mail)
      .with(raw_token)
      .and_return(mailer)

    allow(mailer).to receive(:deliver_later)

    allow_any_instance_of(Account::SendPasswordResetService).to(
      receive(:captcha_invalid?).and_return(false)
    )
  end

  it 'returns true' do
    expect(result.dig('data', 'requestPasswordReset')).to eq(true)
  end

  it 're-generate reset password token' do
    result
    expect(customer.reload.reset_password_token).to eq(reset_password_token)
  end

  it 'updates reset password token generating time' do
    result
    expect(customer.reload.reset_password_sent_at.to_s)
      .to eq(Time.zone.now.to_s)
  end

  it 'sends an email' do
    expect(mailer).to receive(:deliver_later)
    result
  end

  context 'when customer is not found' do
    let(:variables) { { email: Faker::Internet.email, captcha: '' } }

    it 'raises an error' do
      expect(result['errors'].first['message'])
        .to eq(I18n.t('account.request_password_reset.not_found_error'))
    end
  end

  context 'on internal server error' do
    before do
      allow_any_instance_of(Account::SendPasswordResetService)
        .to receive(:call)
        .and_raise(StandardError)
    end

    it 'raises an error' do
      expect(result['errors'].first['message'])
        .to eq(I18n.t('account.request_password_reset.technical_error'))
    end
  end
end
