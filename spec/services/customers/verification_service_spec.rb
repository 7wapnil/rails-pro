describe Customers::VerificationService do
  let(:current_user) { create(:admin_user) }

  let(:customer) do
    create(:customer,
           verified: verified,
           verification_sent: verification_sent,
           email_verified: email_verified)
  end

  let(:valid_input) { { verified: change_verified_to } }

  let(:subject) do
    described_class.new(current_user, customer, valid_input)
  end

  before do
    allow(subject).to receive(:send_verification_email)
    subject.call
    customer.reload
  end

  context 'with customer verified for the first time' do
    let(:verified) { false }
    let(:change_verified_to) { true }
    let(:email_verified) { true }
    let(:verification_sent) { false }

    it 'sends verification email' do
      expect(subject).to have_received(:send_verification_email)
    end

    it 'updates Customer#verified' do
      expect(customer.verified).to be_truthy
    end

    it 'updates Customer#verification_sent' do
      expect(customer.verification_sent).to be_truthy
    end
  end

  context 'with customer un-verified' do
    let(:verified) { true }
    let(:change_verified_to) { false }
    let(:email_verified) { true }
    let(:verification_sent) { true }

    it 'does not send verification email' do
      expect(subject).not_to have_received(:send_verification_email)
    end

    it 'updates Customer#verified' do
      expect(customer.verified).to be_falsey
    end

    it 'does not update Customer#verification_sent' do
      expect(customer.verification_sent).to be_truthy
    end
  end

  context 'with re-verified customer' do
    let(:verified) { false }
    let(:change_verified_to) { true }
    let(:email_verified) { true }
    let(:verification_sent) { true }

    it 'does not send verification email' do
      expect(subject).not_to have_received(:send_verification_email)
    end

    it 'updates Customer#verified' do
      expect(customer.verified).to be_truthy
    end

    it 'does not update Customer#verification_sent' do
      expect(customer.verification_sent).to be_truthy
    end
  end

  context 'with customer verified without verified email' do
    let(:verified) { false }
    let(:change_verified_to) { true }
    let(:email_verified) { false }
    let(:verification_sent) { false }

    it 'does not send verification email' do
      expect(subject).not_to have_received(:send_verification_email)
    end

    it 'updates Customer#verified' do
      expect(customer.verified).to be_truthy
    end

    it 'does not update Customer#verification_sent' do
      expect(customer.verification_sent).to be_falsey
    end
  end
end
