describe Forms::PasswordChange do
  subject(:password_change) { described_class.new }

  it { is_expected.to validate_presence_of(:subject) }
  it { is_expected.to validate_presence_of(:existing_password) }
  it { is_expected.to validate_presence_of(:new_password) }
  it { is_expected.to validate_presence_of(:new_password_confirmation) }

  it { is_expected.to validate_confirmation_of(:new_password) }

  it do
    expect(password_change).to validate_length_of(:new_password)
      .is_at_least(6)
      .is_at_most(32)
  end

  describe '#update_subject_password' do
    it 'returns true if update is successfull' do
      form = described_class.new(
        subject: create(:customer),
        existing_password: 'iamverysecure',
        new_password: 'helloWorld',
        new_password_confirmation: 'helloWorld'
      )

      expect(form.update_subject_password).to be true
    end

    it 'returns false if update is unsuccessful' do
      form = described_class.new(
        subject: create(:customer),
        existing_password: 'iamverySecure',
        new_password: 'helloWorld',
        new_password_confirmation: 'helloWorld'
      )

      expect(form.update_subject_password).to be false
    end

    it 'updates subject password' do
      customer = create(:customer)

      form = described_class.new(
        subject: customer,
        existing_password: 'iamverysecure',
        new_password: 'helloWorld',
        new_password_confirmation: 'helloWorld'
      )

      form.update_subject_password

      expect(customer.valid_password?('helloWorld')).to be true
    end

    it 'raises FormInvalidError if form is invalid' do
      form = described_class.new(
        subject: create(:customer),
        existing_password: 'iamverysecure',
        new_password: 'helloWorld',
        new_password_confirmation: 'helloworld'
      )

      expect { form.update_subject_password }.to raise_error(FormInvalidError)
    end
  end
end
