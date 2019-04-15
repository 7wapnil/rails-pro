describe Forms::WithdrawRequest do
  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_presence_of(:password) }
  it { is_expected.to validate_presence_of(:wallet_id) }
  it { is_expected.to validate_presence_of(:payment_method) }

  it { is_expected.to allow_value(100).for(:amount) }
  it { is_expected.not_to allow_value(100.999).for(:amount) }

  it do
    expect(subject)
      .to validate_inclusion_of(:payment_method)
      .in_array(SafeCharge::Withdraw::AVAILABLE_WITHDRAW_MODES.keys)
  end

  it do
    expect(subject)
      .to validate_numericality_of(:amount)
      .is_greater_than(0)
  end

  context 'credit card' do
    subject do
      described_class.new(payment_method: 'credit_card',
                          password: 'iamverysecure',
                          customer: create(:customer))
    end

    it 'validates presence of holder name and cvv' do
      subject.valid?
      expect(subject.errors).to include(:holder_name, :last_four_digits)
    end

    it 'validates holder name to be not longer than 100 chars' do
      subject.payment_details = [
        { code: 'holder_name', value: Faker::Lorem.characters(101) }
      ]

      subject.valid?
      expect(subject.errors).to include(:holder_name)
    end

    it 'passes valid holder name ' do
      subject.payment_details = [
        { code: 'holder_name', value: 'Test name' }
      ]

      subject.valid?
      expect(subject.errors).not_to include(:holder_name)
    end

    it 'validates last card number digits value is numerical' do
      subject.payment_details = [
        { code: 'last_four_digits', value: 'notnumber' }
      ]

      subject.valid?
      expect(subject.errors).to include(:last_four_digits)
    end

    it 'validates last card number digits value is 4 digits number' do
      subject.payment_details = [
        { code: 'last_four_digits', value: 123 }
      ]

      subject.valid?
      expect(subject.errors).to include(:last_four_digits)
    end

    it 'passes valid last card number digits value' do
      subject.payment_details = [
        { code: 'last_four_digits', value: 1234 }
      ]
      
      subject.valid?
      expect(subject.errors).not_to include(:last_four_digits)
    end
  end
end
