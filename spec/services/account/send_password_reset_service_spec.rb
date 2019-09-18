# frozen_string_literal: true

describe Account::SendPasswordResetService do
  let(:service) { described_class.new(customer: customer, captcha: '') }
  let(:customer) { create :customer, email_verified: email_verified }
  let(:raw_token) { SecureRandom.hex(7) }
  let(:reset_password_token) { SecureRandom.hex(7) }
  let(:mailer) { double }

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

    allow(service).to receive(:captcha_verified?).and_return(true)
  end

  context 'with customer with email_verified == true' do
    let(:email_verified) { true }

    it 'updates token' do
      expect { service.call }.to change(customer, :reset_password_token)
    end

    it 'sends reset password email' do
      service.call
      expect(mailer).to have_received(:deliver_later)
    end
  end

  context 'with customer with email_verified == false' do
    let(:email_verified) { false }

    it 'updates token' do
      expect { service.call }.to change(customer, :reset_password_token)
    end

    it 'sends reset password email' do
      expect(mailer).to receive(:deliver_later)
      service.call
    end
  end

  context 'with customer == nil' do
    let(:customer) {}

    it 'does not send reset password email' do
      service.call
      expect(mailer).not_to have_received(:deliver_later)
    end
  end
end
