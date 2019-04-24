describe Account::SendPasswordResetService do
  let(:service) { described_class.new(customer) }
  let(:customer) { create :customer, email_verified: email_verified }

  before do
    allow(service).to receive(:send_reset_password_mail)
  end

  context 'with customer with email_verified == true' do
    let(:email_verified) { true }

    it 'updates token' do
      expect { service.call }.to change(customer, :reset_password_token)
    end

    it 'sends reset password email' do
      service.call
      expect(service).to have_received(:send_reset_password_mail)
    end
  end

  context 'with customer with email_verified == false' do
    let(:email_verified) { false }

    it 'does not update token' do
      expect { service.call }.not_to change(customer, :reset_password_token)
    end

    it 'does not send reset password email' do
      service.call
      expect(service).not_to have_received(:send_reset_password_mail)
    end
  end

  context 'with customer == nil' do
    let(:customer) { nil }

    it 'does not send reset password email' do
      service.call
      expect(service).not_to have_received(:send_reset_password_mail)
    end
  end
end
